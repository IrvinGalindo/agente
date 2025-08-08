#!/bin/bash
set -e

echo "🚀 Iniciando Multi-App Stack con Ollama optimizado..."
echo "=================================================="

# Función para logging con timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Verificar archivo .env
if [ ! -f .env ]; then
    log "⚠️  Archivo .env no encontrado, creando uno básico..."
    cp .env.example .env 2>/dev/null || {
        log "❌ No se encontró .env.example"
        exit 1
    }
fi

log "✅ Configuración encontrada"

# Crear directorios necesarios
log "📁 Creando directorios..."
mkdir -p ./volumes/{postgres,redis,n8n,ollama,evolution}

# Verificar Docker Compose
if ! command -v docker-compose &> /dev/null; then
    log "❌ Docker Compose no encontrado"
    exit 1
fi

log "🐳 Docker Compose encontrado"

# Limpiar contenedores previos si existen
log "🧹 Limpiando contenedores previos..."
docker-compose down --remove-orphans 2>/dev/null || true

# Construir imágenes
log "🔨 Construyendo imágenes personalizadas..."
docker-compose build --no-cache

# Iniciar servicios en orden
log "🚀 Iniciando servicios..."

# 1. Iniciar base de datos primero
log "  1️⃣ Iniciando PostgreSQL y Redis..."
docker-compose up -d postgres redis

# Esperar a que la base de datos esté lista
log "  ⏳ Esperando PostgreSQL..."
for i in {1..30}; do
    if docker-compose exec postgres pg_isready -U admin > /dev/null 2>&1; then
        log "  ✅ PostgreSQL está listo"
        break
    fi
    if [ $i -eq 30 ]; then
        log "  ❌ PostgreSQL tardó demasiado en iniciar"
        exit 1
    fi
    sleep 2
done

# 2. Iniciar Ollama (toma más tiempo)
log "  2️⃣ Iniciando Ollama..."
docker-compose up -d ollama
sleep 10

# 3. Iniciar aplicaciones principales
log "  3️⃣ Iniciando Evolution API y n8n..."
docker-compose up -d evolution-api n8n

# 4. Iniciar manager web
log "  4️⃣ Iniciando Ollama Manager..."
docker-compose up -d ollama-manager

# 5. Iniciar Nginx al final
log "  5️⃣ Iniciando Nginx..."
docker-compose up -d nginx

# Verificar servicios
log "🔍 Verificando servicios..."
sleep 15

services=("postgres" "redis" "ollama" "evolution-api" "n8n" "ollama-manager" "nginx")
all_healthy=true

for service in "${services[@]}"; do
    if docker-compose ps | grep -q "$service.*Up"; then
        log "  ✅ $service: CORRIENDO"
    else
        log "  ❌ $service: ERROR"
        all_healthy=false
    fi
done

if [ "$all_healthy" = true ]; then
    log ""
    log "🎉 ¡Todos los servicios iniciados correctamente!"
    log ""
    log "📱 URLs disponibles:"
    log "  • Dashboard:     http://localhost/dashboard/"
    log "  • Evolution API: http://localhost/evolution/"
    log "  • n8n:          http://localhost/n8n/"
    log "  • Ollama:       http://localhost/ollama/"
    log "  • Info:         http://localhost/info"
    log ""
    log "🔐 Credenciales por defecto:"
    log "  • n8n:     admin / N8N_Password_Seguro_2024!"
    log "  • Evolution API Key: Evolution_API_Key_Muy_Segura_2024!"
    log ""
    log "📊 Monitoreo:"
    log "  docker-compose logs -f"
    log "  docker-compose ps"
    log ""
    
    # Mostrar logs en vivo
    log "📜 Mostrando logs (Ctrl+C para salir)..."
    docker-compose logs -f
else
    log ""
    log "❌ Algunos servicios fallaron al iniciar"
    log "📜 Mostrando logs de error..."
    docker-compose logs --tail=50
    exit 1
fi
#!/bin/bash
set -e

echo "🚀 Iniciando Multi-App Stack unificado para Render..."
echo "=================================================="

# Función para logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Crear directorios necesarios
log "📁 Creando directorios..."
mkdir -p /var/log/supervisor
mkdir -p /app/n8n-data
mkdir -p /app/evolution-data
mkdir -p /app/ollama/models

# Inicializar PostgreSQL
log "🗄️ Inicializando PostgreSQL..."
chown -R postgres:postgres /var/lib/postgresql/
su - postgres -c "/usr/lib/postgresql/14/bin/initdb -D /var/lib/postgresql/14/main" || true

# Configurar PostgreSQL
log "⚙️ Configurando PostgreSQL..."
echo "listen_addresses = '*'" >> /etc/postgresql/14/main/postgresql.conf
echo "port = 5432" >> /etc/postgresql/14/main/postgresql.conf

# Iniciar PostgreSQL temporalmente para crear la base de datos
log "🔄 Iniciando PostgreSQL temporalmente..."
su - postgres -c "/usr/lib/postgresql/14/bin/pg_ctl -D /var/lib/postgresql/14/main -l /var/log/postgresql.log start" &
sleep 10

# Crear base de datos y usuario
log "👤 Configurando base de datos..."
su - postgres -c "createdb ${POSTGRES_DB:-multiapp}" 2>/dev/null || log "Base de datos ya existe"
su - postgres -c "psql -c \"ALTER USER postgres PASSWORD '${POSTGRES_PASSWORD:-postgres123}';\"" || log "Usuario ya configurado"

# Parar PostgreSQL
su - postgres -c "/usr/lib/postgresql/14/bin/pg_ctl -D /var/lib/postgresql/14/main stop" || true

# Configurar Redis con contraseña desde variable de entorno
log "🔧 Configurando Redis..."
echo "requirepass ${REDIS_PASSWORD}" > /etc/redis/redis.conf
echo "bind 0.0.0.0" >> /etc/redis/redis.conf
echo "port 6379" >> /etc/redis/redis.conf

# Configurar permisos
log "🔐 Configurando permisos..."
chown -R www-data:www-data /var/log/nginx
chown -R redis:redis /var/lib/redis
chmod -R 755 /app

# Instalar modelos de Ollama en segundo plano
log "🦙 Preparando Ollama..."
(
    sleep 60  # Esperar a que Ollama esté disponible
    log "📥 Instalando TinyLlama..."
    /usr/local/bin/ollama pull tinyllama:1.1b-chat-q4_0 2>/dev/null || log "Modelo se instalará bajo demanda"
) &

# Variables de entorno para Render
export PORT=${PORT:-10000}
export OLLAMA_HOST=${OLLAMA_HOST:-0.0.0.0}
export OLLAMA_MODELS=${OLLAMA_MODELS:-/app/ollama/models}
export POSTGRES_USER=${POSTGRES_USER:-postgres}
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres123}
export POSTGRES_DB=${POSTGRES_DB:-multiapp}
export REDIS_PASSWORD=${REDIS_PASSWORD:-redis123}

log "🔧 Variables configuradas:"
log "  - Puerto: $PORT"
log "  - Ollama: $OLLAMA_HOST:11434"
log "  - PostgreSQL: $POSTGRES_USER@$POSTGRES_DB"
log "  - N8N: ${N8N_HOST:-127.0.0.1}:${N8N_PORT:-5678}"
log "  - Evolution: 127.0.0.1:8080"

# Iniciar supervisor con todos los servicios
log "🚀 Iniciando todos los servicios con Supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
#!/bin/bash

# Script de inicio para servicios sin PostgreSQL local
set -e

echo "🚀 Iniciando servicios (sin PostgreSQL local)..."

# Función para verificar si un servicio está funcionando
check_service() {
    local service_name=$1
    local health_url=$2
    local max_attempts=20
    local attempt=1

    echo "⏳ Esperando que $service_name esté disponible..."
    
    while [ $attempt -le $max_attempts ]; do
        if wget --quiet --tries=1 --spider "$health_url" 2>/dev/null; then
            echo "✅ $service_name está funcionando"
            return 0
        fi
        
        echo "🔄 Intento $attempt/$max_attempts para $service_name..."
        sleep 15
        attempt=$((attempt + 1))
    done
    
    echo "❌ $service_name no pudo iniciarse después de $max_attempts intentos"
    return 1
}

# Crear directorios necesarios
mkdir -p /var/log/nginx /var/run /tmp
chmod 755 /var/log/nginx /var/run /tmp

# Verificar variables de entorno importantes
echo "📋 Verificando configuración..."
echo "PORT: ${PORT:-10000}"
echo "N8N_HOST: ${N8N_HOST:-0.0.0.0}"
echo "AUTHENTICATION_API_KEY: ${AUTHENTICATION_API_KEY:0:8}..." 
echo "DATABASE_ENABLED: ${DATABASE_ENABLED:-false}"
echo "CACHE_REDIS_ENABLED: ${CACHE_REDIS_ENABLED:-true}"

# Verificar conexiones externas críticas
echo "🔍 Verificando conexiones externas..."

# Verificar base de datos PostgreSQL (solo si DB_TYPE es postgresdb)
if [ "${DB_TYPE}" = "postgresdb" ]; then
    echo "📊 Verificando conexión a PostgreSQL..."
    if [ -n "${DB_POSTGRESDB_HOST}" ]; then
        echo "PostgreSQL Host: ${DB_POSTGRESDB_HOST}:${DB_POSTGRESDB_PORT}"
    else
        echo "⚠️  Variables de PostgreSQL no configuradas completamente"
    fi
fi

# Verificar Redis (solo si está habilitado)
if [ "${CACHE_REDIS_ENABLED}" = "true" ] && [ -n "${CACHE_REDIS_URI}" ]; then
    echo "🚀 Redis Cache habilitado"
    echo "Redis URI configurado: ${CACHE_REDIS_URI:0:20}..."
fi

# Iniciar Docker daemon si no está corriendo
if ! docker info > /dev/null 2>&1; then
    echo "🐳 Iniciando Docker daemon..."
    dockerd > /var/log/dockerd.log 2>&1 &
    sleep 10
    
    # Verificar que Docker esté funcionando
    timeout=30
    while [ $timeout -gt 0 ]; do
        if docker info > /dev/null 2>&1; then
            echo "✅ Docker daemon iniciado correctamente"
            break
        fi
        echo "⏳ Esperando Docker daemon... ($timeout segundos restantes)"
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        echo "❌ Docker daemon no pudo iniciarse"
        exit 1
    fi
fi

# Iniciar servicios con Docker Compose
echo "🔧 Iniciando servicios con Docker Compose..."
docker-compose up -d --remove-orphans

# Esperar que los servicios estén disponibles
echo "⏳ Esperando que los servicios estén listos..."

# Verificar servicios con timeouts graduales
sleep 30  # Tiempo inicial para que los contenedores inicien

# Verificar Ollama
check_service "Ollama" "http://localhost:11434/api/tags" || echo "⚠️  Ollama no disponible, continuando..."

# Verificar n8n (más tiempo para conectar con PostgreSQL externo)
check_service "n8n" "http://localhost:5678/healthz" || echo "⚠️  n8n no disponible, continuando..."

# Verificar Evolution API  
check_service "Evolution API" "http://localhost:8080/" || echo "⚠️  Evolution API no disponible, continuando..."

# Iniciar Nginx
echo "🌐 Iniciando Nginx..."
nginx -t && echo "✅ Configuración de Nginx válida" || echo "❌ Error en configuración de Nginx"
nginx -g 'daemon off;' &
NGINX_PID=$!

# Función para manejar señales de terminación
cleanup() {
    echo "🛑 Recibida señal de terminación..."
    echo "🔄 Cerrando Nginx..."
    kill $NGINX_PID 2>/dev/null || true
    echo "🔄 Cerrando servicios Docker..."
    docker-compose down --timeout 10
    echo "✅ Limpieza completada"
    exit 0
}

# Configurar manejo de señales
trap cleanup SIGTERM SIGINT

echo "🎉 Deployment completado!"
echo "📊 Panel de estado: /status"
echo "🔧 Ollama: / o /ollama"
echo "⚡ n8n: /n8n" 
echo "📱 Evolution API: /evolution"
echo ""
echo "🔍 Servicios externos configurados:"
echo "   📊 PostgreSQL: ${DB_POSTGRESDB_HOST:-No configurado}"
echo "   🚀 Redis: $([ "${CACHE_REDIS_ENABLED}" = "true" ] && echo "Habilitado" || echo "Deshabilitado")"

# Monitor de servicios
while true; do
    sleep 60
    
    # Verificar que Nginx siga funcionando
    if ! kill -0 $NGINX_PID 2>/dev/null; then
        echo "❌ Nginx se detuvo inesperadamente, reiniciando..."
        nginx -g 'daemon off;' &
        NGINX_PID=$!
    fi
    
    # Mostrar estado cada 5 minutos
    if [ $(($(date +%s) % 300)) -eq 0 ]; then
        echo "📊 Estado de contenedores:"
        docker-compose ps --format table || echo "Error obteniendo estado"
    fi
done

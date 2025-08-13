#!/bin/bash

# Script de inicio optimizado para Render (sin Docker-in-Docker)
set -e

echo "🚀 Iniciando Multi-Service Stack en Render..."
echo "=================================================="

# Función de logging con timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "📁 Creando directorios necesarios..."
mkdir -p /var/log/supervisor /var/log/nginx /home/n8n/.n8n /tmp
chmod 755 /var/log/supervisor /var/log/nginx /home/n8n/.n8n /tmp

log "🔧 Configurando permisos y usuarios..."
# Crear usuario n8n si no existe
if ! id "n8n" &>/dev/null; then
    log "👤 Creando usuario n8n..."
    useradd -m -s /bin/bash n8n
fi

# Configurar directorios para n8n
mkdir -p /home/n8n/.n8n
chown -R n8n:n8n /home/n8n/.n8n

log "📋 Verificando variables de entorno..."
echo "PORT: ${PORT:-10000}"
echo "N8N_HOST: ${N8N_HOST:-0.0.0.0}"
echo "DB_TYPE: ${DB_TYPE:-sqlite}"
echo "AUTHENTICATION_API_KEY: ${AUTHENTICATION_API_KEY:0:8}***"
echo "DATABASE_ENABLED: ${DATABASE_ENABLED:-false}"
echo "CACHE_REDIS_ENABLED: ${CACHE_REDIS_ENABLED:-true}"

# Verificar conexiones externas
log "🔍 Verificando conexiones externas..."

# Test PostgreSQL connection si está configurado
if [ "${DB_TYPE}" = "postgresdb" ] && [ -n "${DB_POSTGRESDB_HOST}" ]; then
    log "📊 Verificando conexión PostgreSQL..."
    if timeout 10 pg_isready -h "${DB_POSTGRESDB_HOST}" -p "${DB_POSTGRESDB_PORT}" -U "${DB_POSTGRESDB_USER}" > /dev/null 2>&1; then
        log "✅ PostgreSQL accesible"
    else
        log "⚠️  PostgreSQL no responde, continuando..."
    fi
fi

# Test Redis connection si está configurado
if [ "${CACHE_REDIS_ENABLED}" = "true" ] && [ -n "${CACHE_REDIS_URI}" ]; then
    log "🚀 Verificando conexión Redis..."
    # Extraer host y puerto de la URI de Redis
    REDIS_HOST=$(echo "${CACHE_REDIS_URI}" | sed -n 's/.*@\([^:]*\):.*/\1/p')
    REDIS_PORT=$(echo "${CACHE_REDIS_URI}" | sed -n 's/.*:\([0-9]*\)$/\1/p')
    
    if [ -n "${REDIS_HOST}" ] && [ -n "${REDIS_PORT}" ]; then
        if timeout 5 redis-cli -h "${REDIS_HOST}" -p "${REDIS_PORT}" ping > /dev/null 2>&1; then
            log "✅ Redis accesible"
        else
            log "⚠️  Redis no responde, continuando..."
        fi
    else
        log "⚠️  No se pudo parsear Redis URI, continuando..."
    fi
fi

log "📦 Instalando dependencias adicionales..."
# Instalar dependencias de Node.js para Evolution API
cd /app
npm init -y > /dev/null 2>&1
npm install express http-proxy-middleware dockerode --save > /dev/null 2>&1 || log "⚠️  Error instalando dependencias npm, continuando..."

log "🔧 Configurando Nginx..."
# Actualizar configuración de Nginx con el puerto correcto desde variable de entorno
NGINX_PORT=${PORT:-10000}
log "📍 Configurando Nginx para puerto: $NGINX_PORT"
sed -i "s/listen 10000;/listen $NGINX_PORT;/g" /etc/nginx/sites-available/default

# Test de configuración de Nginx
if nginx -t > /dev/null 2>&1; then
    log "✅ Configuración Nginx válida"
else
    log "❌ Error en configuración Nginx"
    nginx -t
    exit 1
fi

log "🎯 Configurando variables de entorno para supervisor..."
# Exportar variables para que supervisor las use
export N8N_HOST="${N8N_HOST:-0.0.0.0}"
export N8N_PROTOCOL="${N8N_PROTOCOL:-https}"
export WEBHOOK_URL="${WEBHOOK_URL}"
export N8N_ENCRYPTION_KEY="${N8N_ENCRYPTION_KEY}"
export DB_TYPE="${DB_TYPE}"
export DB_POSTGRESDB_HOST="${DB_POSTGRESDB_HOST}"
export DB_POSTGRESDB_PORT="${DB_POSTGRESDB_PORT}"
export DB_POSTGRESDB_DATABASE="${DB_POSTGRESDB_DATABASE}"
export DB_POSTGRESDB_USER="${DB_POSTGRESDB_USER}"
export DB_POSTGRESDB_PASSWORD="${DB_POSTGRESDB_PASSWORD}"
export N8N_BASIC_AUTH_ACTIVE="${N8N_BASIC_AUTH_ACTIVE:-true}"
export N8N_BASIC_AUTH_USER="${N8N_BASIC_AUTH_USER:-admin}"
export N8N_BASIC_AUTH_PASSWORD="${N8N_BASIC_AUTH_PASSWORD:-password}"
export GENERIC_TIMEZONE="${GENERIC_TIMEZONE:-America/Mexico_City}"

# Variables Evolution API
export SERVER_TYPE="${SERVER_TYPE:-https}"
export SERVER_URL="${SERVER_URL}"
export AUTHENTICATION_API_KEY="${AUTHENTICATION_API_KEY}"
export DATABASE_ENABLED="${DATABASE_ENABLED:-false}"
export DATABASE_PROVIDER="${DATABASE_PROVIDER:-postgresql}"
export DATABASE_CONNECTION_URI="${DATABASE_CONNECTION_URI}"
export DATABASE_CONNECTION_DB_PREFIX_NAME="${DATABASE_CONNECTION_DB_PREFIX_NAME}"
export CACHE_REDIS_ENABLED="${CACHE_REDIS_ENABLED:-true}"
export CACHE_REDIS_URI="${CACHE_REDIS_URI}"
export CACHE_REDIS_PREFIX_KEY="${CACHE_REDIS_PREFIX_KEY:-evolution}"
export CONFIG_SESSION_PHONE_VERSION="${CONFIG_SESSION_PHONE_VERSION}"
export LOG_LEVEL="${LOG_LEVEL:-ERROR}"
export LANGUAGE="${LANGUAGE:-es}"
export CORS_ORIGIN="${CORS_ORIGIN:-*}"
export CORS_METHODS="${CORS_METHODS:-POST,GET,PUT,DELETE}"
export CORS_CREDENTIALS="${CORS_CREDENTIALS:-true}"

log "🚀 Iniciando servicios con Supervisor..."

# Función para cleanup
cleanup() {
    log "🛑 Recibida señal de terminación..."
    log "🔄 Deteniendo servicios..."
    supervisorctl stop all
    killall supervisord 2>/dev/null || true
    log "✅ Servicios detenidos"
    exit 0
}

# Configurar manejo de señales
trap cleanup SIGTERM SIGINT

# Iniciar supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

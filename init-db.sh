#!/bin/bash
set -e

echo "🗄️ Inicializando base de datos PostgreSQL..."

# Función para logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Variables de entorno con valores por defecto
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres123}
POSTGRES_DB=${POSTGRES_DB:-multiapp}

log "📋 Configuración de PostgreSQL:"
log "  - Usuario: $POSTGRES_USER"
log "  - Base de datos: $POSTGRES_DB"

# Crear directorio de datos si no existe
mkdir -p /var/lib/postgresql/14/main

# Inicializar PostgreSQL si no está inicializado
if [ ! -f /var/lib/postgresql/14/main/PG_VERSION ]; then
    log "🔄 Inicializando cluster de PostgreSQL..."
    chown -R postgres:postgres /var/lib/postgresql/
    su - postgres -c "/usr/lib/postgresql/14/bin/initdb -D /var/lib/postgresql/14/main"
else
    log "✅ PostgreSQL ya está inicializado"
fi

# Configurar PostgreSQL
log "⚙️ Configurando PostgreSQL..."
echo "listen_addresses = '*'" >> /etc/postgresql/14/main/postgresql.conf
echo "port = 5432" >> /etc/postgresql/14/main/postgresql.conf
echo "max_connections = 100" >> /etc/postgresql/14/main/postgresql.conf
echo "shared_buffers = 128MB" >> /etc/postgresql/14/main/postgresql.conf

# Configurar autenticación
echo "local   all             postgres                                peer" > /etc/postgresql/14/main/pg_hba.conf
echo "local   all             all                                     md5" >> /etc/postgresql/14/main/pg_hba.conf
echo "host    all             all             127.0.0.1/32            md5" >> /etc/postgresql/14/main/pg_hba.conf
echo "host    all             all             ::1/128                 md5" >> /etc/postgresql/14/main/pg_hba.conf

log "✅ Configuración de PostgreSQL completada"
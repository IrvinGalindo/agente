#!/bin/bash
set -e

echo "🚀 Inicializando contenedor multi-servicios..."

# Crear carpetas necesarias
mkdir -p /var/lib/postgresql/data
mkdir -p /root/.ollama/models

# Iniciar PostgreSQL en segundo plano para configuración inicial
echo "📦 Configurando base de datos..."
pg_ctl initdb -D /var/lib/postgresql/data
pg_ctl start -D /var/lib/postgresql/data
sleep 5
psql -U postgres -c "ALTER USER postgres PASSWORD '${POSTGRES_PASSWORD}';"
pg_ctl stop -D /var/lib/postgresql/data

# Arrancar supervisor
echo "🛠️ Iniciando supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

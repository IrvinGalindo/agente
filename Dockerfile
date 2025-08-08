# Dockerfile unificado para todos los servicios - Versión simplificada
FROM ubuntu:22.04

# Evitar prompts interactivos
ENV DEBIAN_FRONTEND=noninteractive

# Variables de entorno con valores por defecto
ENV PORT=10000
ENV NODE_ENV=production
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_MODELS=/app/ollama/models
ENV OLLAMA_KEEP_ALIVE=5m
ENV OLLAMA_MAX_LOADED_MODELS=1
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres123
ENV POSTGRES_DB=multiapp
ENV REDIS_PASSWORD=redis123
ENV N8N_HOST=0.0.0.0
ENV N8N_PORT=5678
ENV TIMEZONE=America/Mexico_City

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg2 \
    software-properties-common \
    supervisor \
    nginx \
    postgresql \
    postgresql-contrib \
    redis-server \
    python3 \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Instalar Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Instalar Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Crear directorios de trabajo
WORKDIR /app
RUN mkdir -p /app/{ollama-manager,n8n-data,evolution-data,ollama/models}

# ===============================
# OLLAMA MANAGER
# ===============================
# Copiar archivos del manager
COPY package.json server.js /app/ollama-manager/
COPY public/ /app/ollama-manager/public/

RUN cd /app/ollama-manager && npm install --production

# ===============================
# N8N SETUP
# ===============================
RUN npm install -g n8n

# ===============================
# EVOLUTION API
# ===============================
RUN cd /app && \
    git clone https://github.com/EvolutionAPI/evolution-api.git evolution-api && \
    cd evolution-api && \
    npm install --production

# ===============================
# CONFIGURACIÓN NGINX (INLINE)
# ===============================
RUN echo 'user www-data;\nworker_processes auto;\npid /run/nginx.pid;\nevents {\n    worker_connections 1024;\n}\nhttp {\n    include /etc/nginx/mime.types;\n    default_type application/octet-stream;\n    access_log /var/log/nginx/access.log;\n    error_log /var/log/nginx/error.log;\n    sendfile on;\n    keepalive_timeout 65;\n    client_max_body_size 100M;\n    map $http_upgrade $connection_upgrade {\n        default upgrade;\n        '"'"''"'"' close;\n    }\n    server {\n        listen 10000;\n        server_name _;\n        location / {\n            proxy_pass http://127.0.0.1:3000;\n            proxy_set_header Host $host;\n            proxy_set_header X-Real-IP $remote_addr;\n            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n            proxy_set_header X-Forwarded-Proto $scheme;\n        }\n        location /evolution {\n            rewrite ^/evolution(/.*)$ $1 break;\n            proxy_pass http://127.0.0.1:8080;\n            proxy_set_header Host $host;\n            proxy_set_header X-Real-IP $remote_addr;\n            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n            proxy_set_header X-Forwarded-Proto $scheme;\n            proxy_http_version 1.1;\n            proxy_set_header Upgrade $http_upgrade;\n            proxy_set_header Connection $connection_upgrade;\n        }\n        location /n8n {\n            rewrite ^/n8n(/.*)$ $1 break;\n            proxy_pass http://127.0.0.1:5678;\n            proxy_set_header Host $host;\n            proxy_set_header X-Real-IP $remote_addr;\n            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n            proxy_set_header X-Forwarded-Proto $scheme;\n            proxy_http_version 1.1;\n            proxy_set_header Upgrade $http_upgrade;\n            proxy_set_header Connection $connection_upgrade;\n        }\n        location /ollama {\n            rewrite ^/ollama(/.*)$ $1 break;\n            proxy_pass http://127.0.0.1:11434;\n            proxy_set_header Host $host;\n            proxy_set_header X-Real-IP $remote_addr;\n            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n            proxy_set_header X-Forwarded-Proto $scheme;\n            proxy_read_timeout 300s;\n        }\n        location /api {\n            proxy_pass http://127.0.0.1:11434/api;\n            proxy_set_header Host $host;\n            proxy_set_header X-Real-IP $remote_addr;\n            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n            proxy_set_header X-Forwarded-Proto $scheme;\n            proxy_read_timeout 300s;\n        }\n        location /health {\n            return 200 "healthy - all services running\\n";\n            add_header Content-Type text/plain;\n        }\n    }\n}' > /etc/nginx/nginx.conf

# ===============================
# CONFIGURACIÓN SUPERVISOR (INLINE)
# ===============================
RUN echo '[supervisord]\nnodaemon=true\nlogfile=/var/log/supervisor/supervisord.log\npidfile=/var/run/supervisord.pid\n[program:postgresql]\ncommand=/usr/lib/postgresql/14/bin/postgres -D /var/lib/postgresql/14/main -c config_file=/etc/postgresql/14/main/postgresql.conf\nuser=postgres\nautorestart=true\nstdout_logfile=/var/log/supervisor/postgresql.log\nstderr_logfile=/var/log/supervisor/postgresql.log\npriority=100\n[program:redis]\ncommand=/usr/bin/redis-server /etc/redis/redis.conf\nuser=redis\nautorestart=true\nstdout_logfile=/var/log/supervisor/redis.log\nstderr_logfile=/var/log/supervisor/redis.log\npriority=200\n[program:ollama]\ncommand=/usr/local/bin/ollama serve\nenvironment=OLLAMA_HOST=%(ENV_OLLAMA_HOST)s,OLLAMA_MODELS=%(ENV_OLLAMA_MODELS)s,OLLAMA_KEEP_ALIVE=%(ENV_OLLAMA_KEEP_ALIVE)s,OLLAMA_MAX_LOADED_MODELS=%(ENV_OLLAMA_MAX_LOADED_MODELS)s\nautorestart=true\nstdout_logfile=/var/log/supervisor/ollama.log\nstderr_logfile=/var/log/supervisor/ollama.log\npriority=300\n[program:ollama-manager]\ncommand=npm start\ndirectory=/app/ollama-manager\nenvironment=PORT=3000,OLLAMA_URL=http://127.0.0.1:11434,NODE_ENV=%(ENV_NODE_ENV)s\nautorestart=true\nstdout_logfile=/var/log/supervisor/ollama-manager.log\nstderr_logfile=/var/log/supervisor/ollama-manager.log\npriority=400\n[program:n8n]\ncommand=n8n start\nenvironment=N8N_HOST=%(ENV_N8N_HOST)s,N8N_PORT=%(ENV_N8N_PORT)s,N8N_BASIC_AUTH_ACTIVE=%(ENV_N8N_BASIC_AUTH_ACTIVE)s,N8N_BASIC_AUTH_USER=%(ENV_N8N_BASIC_AUTH_USER)s,N8N_BASIC_AUTH_PASSWORD=%(ENV_N8N_BASIC_AUTH_PASSWORD)s,DB_TYPE=%(ENV_N8N_DB_TYPE)s,DB_POSTGRESDB_HOST=127.0.0.1,DB_POSTGRESDB_PORT=5432,DB_POSTGRESDB_DATABASE=%(ENV_N8N_DB_NAME)s,DB_POSTGRESDB_USER=%(ENV_POSTGRES_USER)s,DB_POSTGRESDB_PASSWORD=%(ENV_POSTGRES_PASSWORD)s,N8N_ENCRYPTION_KEY=%(ENV_N8N_ENCRYPTION_KEY)s,N8N_USER_FOLDER=/app/n8n-data,GENERIC_TIMEZONE=%(ENV_TIMEZONE)s,WEBHOOK_URL=%(ENV_N8N_WEBHOOK_URL)s,N8N_PROTOCOL=%(ENV_N8N_PROTOCOL)s\nautorestart=true\nstdout_logfile=/var/log/supervisor/n8n.log\nstderr_logfile=/var/log/supervisor/n8n.log\npriority=500\n[program:evolution-api]\ncommand=npm start\ndirectory=/app/evolution-api\nenvironment=SERVER_TYPE=%(ENV_EVOLUTION_SERVER_TYPE)s,SERVER_PORT=8080,DEL_INSTANCE=%(ENV_EVOLUTION_DEL_INSTANCE)s,DATABASE_ENABLED=%(ENV_DATABASE_ENABLED)s,DATABASE_CONNECTION_URI=%(ENV_DATABASE_CONNECTION_URI)s,DATABASE_CONNECTION_DB_PREFIX_NAME=%(ENV_DATABASE_CONNECTION_DB_PREFIX_NAME)s,REDIS_ENABLED=%(ENV_REDIS_ENABLED)s,REDIS_URI=%(ENV_REDIS_URI)s,REDIS_PREFIX_KEY=%(ENV_REDIS_PREFIX_KEY)s,AUTHENTICATION_TYPE=%(ENV_EVOLUTION_AUTH_TYPE)s,AUTHENTICATION_API_KEY=%(ENV_EVOLUTION_API_KEY)s,AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=%(ENV_EVOLUTION_EXPOSE_FETCH)s,LANGUAGE=%(ENV_EVOLUTION_LANGUAGE)s,LOG_LEVEL=%(ENV_LOG_LEVEL)s,LOG_COLOR=%(ENV_LOG_COLOR)s,LOG_BAILEYS=%(ENV_LOG_BAILEYS)s,CONFIG_SESSION_PHONE_CLIENT=%(ENV_CONFIG_SESSION_PHONE_CLIENT)s,CONFIG_SESSION_PHONE_NAME=%(ENV_CONFIG_SESSION_PHONE_NAME)s\nautorestart=true\nstdout_logfile=/var/log/supervisor/evolution.log\nstderr_logfile=/var/log/supervisor/evolution.log\npriority=600\n[program:nginx]\ncommand=/usr/sbin/nginx -g "daemon off;"\nautorestart=true\nstdout_logfile=/var/log/supervisor/nginx.log\nstderr_logfile=/var/log/supervisor/nginx.log\npriority=700' > /etc/supervisor/conf.d/supervisord.conf

# ===============================
# SCRIPT DE INICIO (INLINE)
# ===============================
RUN echo '#!/bin/bash\nset -e\necho "🚀 Iniciando Multi-App Stack unificado para Render..."\necho "=================================================="\nlog() {\n    echo "[$(date '"'"'+%Y-%m-%d %H:%M:%S'"'"')] $1"\n}\nlog "📁 Creando directorios..."\nmkdir -p /var/log/supervisor\nmkdir -p /app/n8n-data\nmkdir -p /app/evolution-data\nmkdir -p /app/ollama/models\nlog "🗄️ Inicializando PostgreSQL..."\nchown -R postgres:postgres /var/lib/postgresql/\nsu - postgres -c "/usr/lib/postgresql/14/bin/initdb -D /var/lib/postgresql/14/main" || true\nlog "⚙️ Configurando PostgreSQL..."\necho "listen_addresses = '"'"'*'"'"'" >> /etc/postgresql/14/main/postgresql.conf\necho "port = 5432" >> /etc/postgresql/14/main/postgresql.conf\nlog "🔄 Iniciando PostgreSQL temporalmente..."\nsu - postgres -c "/usr/lib/postgresql/14/bin/pg_ctl -D /var/lib/postgresql/14/main -l /var/log/postgresql.log start" &\nsleep 10\nlog "👤 Configurando base de datos..."\nsu - postgres -c "createdb ${POSTGRES_DB:-multiapp}" 2>/dev/null || log "Base de datos ya existe"\nsu - postgres -c "psql -c \\"ALTER USER postgres PASSWORD '"'"'${POSTGRES_PASSWORD:-postgres123}'"'"';\\"" || log "Usuario ya configurado"\nsu - postgres -c "/usr/lib/postgresql/14/bin/pg_ctl -D /var/lib/postgresql/14/main stop" || true\nlog "🔧 Configurando Redis..."\necho "requirepass ${REDIS_PASSWORD}" > /etc/redis/redis.conf\necho "bind 0.0.0.0" >> /etc/redis/redis.conf\necho "port 6379" >> /etc/redis/redis.conf\nlog "🔐 Configurando permisos..."\nchown -R www-data:www-data /var/log/nginx\nchown -R redis:redis /var/lib/redis\nchmod -R 755 /app\nlog "🦙 Preparando Ollama..."\n(\n    sleep 60\n    log "📥 Instalando TinyLlama..."\n    /usr/local/bin/ollama pull tinyllama:1.1b-chat-q4_0 2>/dev/null || log "Modelo se instalará bajo demanda"\n) &\nexport PORT=${PORT:-10000}\nexport OLLAMA_HOST=${OLLAMA_HOST:-0.0.0.0}\nexport OLLAMA_MODELS=${OLLAMA_MODELS:-/app/ollama/models}\nexport POSTGRES_USER=${POSTGRES_USER:-postgres}\nexport POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres123}\nexport POSTGRES_DB=${POSTGRES_DB:-multiapp}\nexport REDIS_PASSWORD=${REDIS_PASSWORD:-redis123}\nlog "🔧 Variables configuradas:"\nlog "  - Puerto: $PORT"\nlog "  - Ollama: $OLLAMA_HOST:11434"\nlog "  - PostgreSQL: $POSTGRES_USER@$POSTGRES_DB"\nlog "  - N8N: ${N8N_HOST:-127.0.0.1}:${N8N_PORT:-5678}"\nlog "  - Evolution: 127.0.0.1:8080"\nlog "🚀 Iniciando todos los servicios con Supervisor..."\nexec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf' > /app/start-services.sh && chmod +x /app/start-services.sh

# ===============================
# CONFIGURACIÓN DE POSTGRESQL
# ===============================
RUN mkdir -p /var/lib/postgresql/14/main && \
    chown -R postgres:postgres /var/lib/postgresql/

# ===============================
# CONFIGURACIÓN DE REDIS
# ===============================
RUN mkdir -p /var/lib/redis && \
    chown -R redis:redis /var/lib/redis

# Exponer puerto
EXPOSE $PORT

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:$PORT/health || exit 1

# Comando de inicio
CMD ["/app/start-services.sh"]

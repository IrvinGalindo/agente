# Dockerfile unificado para todos los servicios
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
# CONFIGURACIÓN NGINX
# ===============================
COPY nginx.conf /etc/nginx/nginx.conf

# ===============================
# CONFIGURACIÓN SUPERVISOR
# ===============================
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# ===============================
# SCRIPTS DE INICIO
# ===============================
COPY start-services.sh /app/start-services.sh
COPY init-db.sh /app/init-db.sh
RUN chmod +x /app/start-services.sh /app/init-db.sh

# ===============================
# CONFIGURACIÓN DE POSTGRESQL
# ===============================
RUN service postgresql start && \
    su - postgres -c "createuser --superuser root" && \
    su - postgres -c "createdb multiapp" && \
    su - postgres -c "psql -c \"ALTER USER postgres PASSWORD 'postgres123';\"" && \
    service postgresql stop

# ===============================
# CONFIGURACIÓN DE REDIS
# ===============================
RUN echo "requirepass redis123" >> /etc/redis/redis.conf
RUN echo "bind 0.0.0.0" >> /etc/redis/redis.conf

# Exponer puerto
EXPOSE $PORT

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:$PORT/health || exit 1

# Comando de inicio
CMD ["/app/start-services.sh"]

FROM node:18-bullseye

# Instalar dependencias del sistema (Postgres, Redis, Ollama, Nginx, supervisord)
RUN apt-get update && apt-get install -y \
    curl bash nginx redis-server postgresql postgresql-contrib \
    supervisor git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ======================
# Variables de entorno
# ======================
ENV NODE_ENV=production
ENV PORT=80
ENV OLLAMA_HOST=0.0.0.0
ENV PATH=$PATH:/usr/lib/postgresql/15/bin

# ======================
# Crear estructura
# ======================
WORKDIR /app

# Copiar Manager (Node.js)
COPY package.json ./
RUN npm install --only=production
COPY server.js ./
COPY public/ ./public/

# Copiar Nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copiar scripts y supervisord config
COPY start.sh /start.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chmod +x /start.sh

# ======================
# Instalar n8n
# ======================
RUN npm install -g n8n

# ======================
# Instalar Evolution API
# ======================
RUN git clone https://github.com/atendai/evolution-api /opt/evolution-api \
    && cd /opt/evolution-api \
    && npm install --only=production

# ======================
# Instalar Ollama
# ======================
RUN curl -fsSL https://ollama.com/download/OllamaLinux | sh

# ======================
# Exponer puerto
# ======================
EXPOSE 80

# ======================
# Iniciar todo
# ======================
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

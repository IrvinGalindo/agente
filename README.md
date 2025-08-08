# Multi-Service Deployment en Render

Este proyecto despliega tres servicios integrados en una sola instancia de Render:
- **Ollama**: LLM local
- **n8n**: Automatización de workflows  
- **Evolution API**: API de WhatsApp

## 🚀 Estructura del Proyecto

```
/
├── Dockerfile.manager     # Dockerfile principal
├── docker-compose.yml     # Orquestación de servicios  
├── nginx.conf            # Configuración del reverse proxy
├── start.sh              # Script de inicio
└── .env.example          # Variables de entorno de ejemplo
```

## 🛠️ Configuración en Render

### 1. Configuración del Servicio

- **Build Command**: Dejar vacío
- **Start Command**: Dejar vacío (usa el CMD del Dockerfile)
- **Dockerfile Path**: `Dockerfile.manager`
- **Environment**: Docker

### 2. Variables de Entorno Requeridas

Configura estas variables en Render:

#### Variables Básicas
```bash
PORT=10000  # Render lo configura automáticamente
N8N_ENCRYPTION_KEY=tu-clave-de-32-caracteres-muy-segura
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=tu-password-seguro
AUTHENTICATION_API_KEY=tu-api-key-de-evolution
```

#### Variables de URL (reemplaza con tu dominio de Render)
```bash
WEBHOOK_URL=https://tu-app.onrender.com
SERVER_URL=https://tu-app.onrender.com
```

### 3. Variables Opcionales
```bash
GENERIC_TIMEZONE=America/Mexico_City
LANGUAGE=es
LOG_LEVEL=ERROR
```

## 🌐 Rutas de Acceso

Una vez desplegado, accede a los servicios mediante:

- **Ollama**: `https://tu-app.onrender.com/` o `https://tu-app.onrender.com/ollama`
- **n8n**: `https://tu-app.onrender.com/n8n`
- **Evolution API**: `https://tu-app.onrender.com/evolution`
- **Estado**: `https://tu-app.onrender.com/status`
- **Health Check**: `https://tu-app.onrender.com/health`

## 🔧 APIs Importantes

### Ollama API
```bash
# Listar modelos
curl https://tu-app.onrender.com/api/tags

# Chat
curl https://tu-app.onrender.com/api/chat \
  -d '{"model": "llama2", "messages": [{"role": "user", "content": "Hola"}]}'
```

### Evolution API
```bash
# Crear instancia
curl https://tu-app.onrender.com/evolution/instance/create \
  -H "apikey: tu-api-key" \
  -H "Content-Type: application/json" \
  -d '{"instanceName": "mi-instancia"}'
```

### n8n
- Interface web: `https://tu-app.onrender.com/n8n`
- Usuario: `admin` (o el configurado en N8N_BASIC_AUTH_USER)
- Password: El configurado en N8N_BASIC_AUTH_PASSWORD

## 📋 Pasos de Deployment

1. **Subir código** a tu repositorio de GitHub
2. **Crear servicio** en Render conectado al repo
3. **Configurar variables** de entorno en Render
4. **Seleccionar** `Dockerfile.manager` como Dockerfile
5. **Esperar** el deployment (puede tomar 10-15 minutos)
6. **Verificar** accediendo a `/status`

## 🔍 Troubleshooting

### Si los servicios no inician:
1. Revisa los logs de Render
2. Verifica que todas las variables de entorno estén configuradas
3. Asegúrate de que el `Dockerfile.manager` esté seleccionado

### Si las rutas no funcionan:
1. Verifica que nginx esté funcionando: `/health`
2. Revisa el estado de los contenedores: `/status`
3. Asegúrate de usar las rutas correctas con prefijos

### Si hay problemas de memoria:
- Los servicios requieren al menos 2GB de RAM
- Considera optimizar las configuraciones de cada servicio

## 🚨 Consideraciones Importantes

1. **Tiempo de inicio**: Los servicios pueden tardar 5-10 minutos en estar completamente operativos
2. **Persistencia**: Los datos se pierden en cada redeploy (usar BD externa si necesitas persistencia)
3. **Recursos**: Requiere instancia con suficiente RAM (mínimo 2GB recomendado)
4. **Timeouts**: Render puede hacer timeout si el inicio toma más de 15 minutos

## 🔐 Seguridad

- Cambia todas las contraseñas y API keys por defecto
- Usa HTTPS en producción (Render lo proporciona automáticamente)
- Restringe acceso mediante autenticación básica en n8n
- Configura CORS apropiadamente para Evolution API

## 📊 Monitoreo

- Health check: `GET /health`
- Status de servicios: `GET /status`  
- Logs disponibles en Render dashboard

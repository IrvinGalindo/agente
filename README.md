🐳 Multi-App Docker Stack con Ollama Optimizado
Este proyecto contiene una configuración Docker Compose con múltiples aplicaciones integradas, optimizada para Render gratuito con modelos LLM pre-instalados.

🛠️ Servicios Incluidos
Servicio	Puerto	Descripción	URL
🦙 Ollama Manager	3000	Interface web para gestionar Ollama	/dashboard/
📱 Evolution API	8080	API completa para WhatsApp Business	/evolution/
⚡ n8n	5678	Automatización visual de workflows	/n8n/
🤖 Ollama	11434	Servidor LLM con TinyLlama pre-instalado	/ollama/
🗄️ PostgreSQL	5432	Base de datos principal	-
⚡ Redis	6379	Cache y almacenamiento rápido	-
🌐 Nginx	80	Proxy reverso (puerto principal)	/
📁 Estructura del Proyecto
mi-proyecto-docker/
├── docker-compose.yml          # Configuración principal
├── .env                       # Variables de entorno
├── Dockerfile.ollama          # Ollama con modelo pre-instalado
├── Dockerfile.manager         # Interface web para Ollama
├── Dockerfile.nginx           # Proxy reverso
├── start.sh                   # Script de inicio automático
├── .dockerignore             # Archivos a excluir del build
├── README.md                  # Esta documentación
└── render.yaml               # Configuración para Render
🚀 Instalación Rápida
1. Descargar archivos
bash
mkdir mi-multiapp-docker
cd mi-multiapp-docker
# Copia todos los archivos aquí
2. Configurar variables (IMPORTANTE)
bash
# Editar .env y cambiar TODAS las contraseñas:
nano .env

# Cambiar obligatoriamente:
POSTGRES_PASSWORD=PostgreSQL_Seguro_2024!
REDIS_PASSWORD=Redis_Seguro_2024!
EVOLUTION_API_KEY=Evolution_API_Key_Muy_Segura_2024!
N8N_BASIC_AUTH_PASSWORD=N8N_Password_Seguro_2024!
N8N_ENCRYPTION_KEY=N8N_Encryption_Key_Super_Larga_Y_Muy_Segura_2024_123456789
3. Ejecutar localmente
bash
# Dar permisos al script
chmod +x start.sh

# Iniciar todo automáticamente
./start.sh

# O manualmente:
docker-compose up -d
4. Acceder a los servicios
Dashboard Principal: http://localhost/dashboard/
Evolution API: http://localhost/evolution/
n8n Workflows: http://localhost/n8n/
Ollama API: http://localhost/ollama/
Info General: http://localhost/info
🦙 Ollama Optimizado para Render Gratuito
Modelos Pre-instalados:
✅ TinyLlama (637MB) - Instalado automáticamente
✅ TinyLlama Chat (400MB) - Versión optimizada para chat
⚠️ Qwen2 0.5B (500MB) - Disponible para instalación manual
Gestión desde el Dashboard:
Ve a /dashboard/
Usa la sección "📦 Modelos Disponibles"
Haz clic en "TinyLlama" para instalarlo
Prueba el modelo en la sección "💬 Probar Modelo"
API Direct:
bash
# Listar modelos
curl http://localhost/ollama/api/tags

# Generar texto
curl -X POST http://localhost/ollama/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "tinyllama",
    "prompt": "Hola, ¿cómo estás?",
    "stream": false
  }'
🌐 Despliegue en Render
Método 1: Docker Compose
Sube el código a GitHub
Conecta tu repo a Render
Crear Web Service:
Build Command: docker-compose build
Start Command: docker-compose up nginx
Port: 80
Método 2: Variables de Entorno en Render
En Render Dashboard > Environment, agregar:

bash
POSTGRES_PASSWORD=PostgreSQL_Seguro_2024!
REDIS_PASSWORD=Redis_Seguro_2024!
EVOLUTION_API_KEY=Evolution_API_Key_Muy_Segura_2024!
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=N8N_Password_Seguro_2024!
N8N_ENCRYPTION_KEY=N8N_Encryption_Key_Super_Larga_Y_Muy_Segura_2024_123456789
N8N_WEBHOOK_URL=https://tu-app.onrender.com
PORT=80
URLs en Render:
Una vez desplegado:

Dashboard: https://tu-app.onrender.com/dashboard/
Evolution: https://tu-app.onrender.com/evolution/
n8n: https://tu-app.onrender.com/n8n/
Ollama: https://tu-app.onrender.com/ollama/
🔐 Credenciales por Defecto
n8n
Usuario: admin
Contraseña: N8N_Password_Seguro_2024!
Evolution API
API Key: Evolution_API_Key_Muy_Segura_2024!
Base de datos PostgreSQL
Usuario: admin
Contraseña: PostgreSQL_Seguro_2024!
Base: multiapp_db
📊 Uso de las APIs
Evolution API - WhatsApp
bash
# Crear instancia
curl -X POST https://tu-app.onrender.com/evolution/instance/create \
  -H "apikey: Evolution_API_Key_Muy_Segura_2024!" \
  -H "Content-Type: application/json" \
  -d '{"instanceName": "mi-whatsapp"}'

# Obtener QR
curl https://tu-app.onrender.com/evolution/instance/qrcode/mi-whatsapp \
  -H "apikey: Evolution_API_Key_Muy_Segura_2024!"
n8n - Workflows
Ve a /n8n/
Login: admin / N8N_Password_Seguro_2024!
Crea workflows arrastrando nodos
Conecta con Evolution API y Ollama
Ollama - LLM
bash
# Modelos disponibles
curl https://tu-app.onrender.com/ollama/api/tags

# Generar texto
curl -X POST https://tu-app.onrender.com/ollama/api/generate \
  -d '{"model":"tinyllama","prompt":"Explica qué es Docker","stream":false}'

# Instalar nuevo modelo (solo pequeños)
curl -X POST https://tu-app.onrender.com/ollama/api/pull \
  -d '{"name":"qwen2:0.5b"}'
🔧 Comandos Útiles
Desarrollo Local
bash
# Ver logs en vivo
docker-compose logs -f

# Restart solo un servicio
docker-compose restart ollama

# Rebuild sin cache
docker-compose build --no-cache ollama

# Ver estado de servicios
docker-compose ps

# Entrar a un contenedor
docker-compose exec ollama bash
Monitoreo
bash
# Uso de recursos
docker stats

# Logs específicos
docker-compose logs ollama
docker-compose logs evolution-api

# Limpiar todo
docker-compose down -v
Backup
bash
# Backup PostgreSQL
docker-compose exec postgres pg_dump -U admin multiapp_db > backup.sql

# Backup volúmenes
docker run --rm -v mi-proyecto-docker_postgres_data:/data \
  -v $(pwd):/backup alpine \
  tar czf /backup/postgres_backup.tar.gz /data
⚠️ Limitaciones Render Gratuito
Recursos:
RAM: 512MB (suficiente para TinyLlama)
CPU: Limitada
Disco: Temporal (volúmenes se pierden al dormir)
Sleep: 15 min sin actividad
Soluciones:
Modelos pequeños: Solo TinyLlama, Qwen2 0.5B
Keep-alive: Ping automático cada 10 min
Re-instalación: Scripts automáticos al despertar
Upgrade: Plan Pro ($7/mes) = 2GB RAM
🔍 Troubleshooting
Problemas Comunes
❌ Ollama no instala modelos

bash
# Ver logs
docker-compose logs ollama

# Restart manual
docker-compose restart ollama

# Instalar desde dashboard
# Ve a /dashboard/ > "TinyLlama"
❌ n8n no conecta a PostgreSQL

bash
# Verificar PostgreSQL
docker-compose exec postgres pg_isready -U admin

# Verificar variables
docker-compose config
❌ Evolution API no inicia

bash
# Ver logs específicos
docker-compose logs evolution-api

# Verificar Redis
docker-compose exec redis redis-cli ping
Logs de Debug
bash
# Todos los logs
docker-compose logs

# Solo errores
docker-compose logs | grep ERROR

# Últimas 50 líneas
docker-compose logs --tail=50
🚀 Optimizaciones Avanzadas
Para Render Pro (2GB RAM)
bash
# En .env cambiar:
OLLAMA_MAX_LOADED_MODELS=2
# Y agregar modelos más grandes:
# phi3:mini, llama3.2:1b
Keep-Alive Automático
bash
# Crear cron job (en tu servidor local)
*/10 * * * * curl -s https://tu-app.onrender.com/health > /dev/null
Auto-rebuild en GitHub Actions
yaml
# .github/workflows/deploy.yml
name: Deploy to Render
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Trigger Render Deploy
        run: |
          curl -X POST "https://api.render.com/deploy/srv-YOUR_SERVICE_ID"
🎯 Casos de Uso
1. Bot de WhatsApp con IA
Evolution API recibe mensajes
n8n procesa y filtra
Ollama genera respuestas inteligentes
Evolution API envía respuesta
2. Automatización de Procesos
n8n monitorea APIs/emails
Procesa con Ollama
Envía notificaciones por WhatsApp
Guarda datos en PostgreSQL
3. Dashboard de IA
Interface web para múltiples LLMs
Chat directo con modelos
Gestión de conversaciones
Analytics y reportes
📞 Soporte
GitHub Issues: Para reportar bugs
Render Docs: https://render.com/docs
Docker Docs: https://docs.docker.com
Ollama Models: https://ollama.ai/library
**🎉 ¡Tu stack multi-app está listo para producción!**bash

Cambiar TODAS las contraseñas por unas seguras
POSTGRES_PASSWORD=tu_password_postgresql_seguro_123
REDIS_PASSWORD=tu_password_redis_seguro_123
EVOLUTION_API_KEY=tu_api_key_evolution_muy_segura_123
N8N_BASIC_AUTH_PASSWORD=tu_password_n8n_seguro_123
N8N_ENCRYPTION_KEY=tu_clave_encriptacion_n8n_muy_larga_y_segura_123456789

Para producción, cambiar la URL de webhook
N8N_WEBHOOK_URL=https://tu-dominio.onrender.com


### 3. Ejecutar Localmente

```bash
# Iniciar todos los servicios
docker-compose up -d

# Ver logs
docker-compose logs -f

# Parar servicios
docker-compose down
🌐 Despliegue en Render
Opción 1: Docker Compose (Recomendado)
Crear nuevo Web Service en Render
Conectar tu repositorio de GitHub
Configurar el servicio:
Build Command: docker-compose build
Start Command: docker-compose up
Port: 8080
Agregar Variables de Entorno: En Render Dashboard > Environment, agregar todas las variables del archivo .env
Opción 2: Servicios Separados
Crear un servicio separado para cada aplicación:

Evolution API: Puerto 8080
n8n: Puerto 5678
Ollama: Puerto 11434
PostgreSQL: Como base de datos externa
Redis: Como servicio de cache
📋 URLs de Acceso
Una vez desplegado, podrás acceder a:

Evolution API: https://tu-app.onrender.com:8080
n8n Interface: https://tu-app.onrender.com:5678
Ollama API: https://tu-app.onrender.com:11434
🔐 Credenciales por Defecto
n8n
Usuario: admin (configurable en .env)
Contraseña: Definida en N8N_BASIC_AUTH_PASSWORD
Evolution API
API Key: Definida en EVOLUTION_API_KEY
📊 Uso de las APIs
Evolution API - Ejemplos
bash
# Crear instancia de WhatsApp
curl -X POST https://tu-app.onrender.com:8080/instance/create \
  -H "apikey: tu_api_key_evolution_muy_segura_123" \
  -H "Content-Type: application/json" \
  -d '{"instanceName": "mi-instancia"}'

# Obtener QR Code
curl https://tu-app.onrender.com:8080/instance/qrcode/mi-instancia \
  -H "apikey: tu_api_key_evolution_muy_segura_123"
Ollama - Ejemplos
bash
# Descargar modelo
curl -X POST https://tu-app.onrender.com:11434/api/pull \
  -d '{"name": "llama2"}'

# Generar texto
curl -X POST https://tu-app.onrender.com:11434/api/generate \
  -d '{"model": "llama2", "prompt": "Hola, ¿cómo estás?"}'
🔧 Configuración Avanzada
Modelos de Ollama
Para instalar modelos específicos, conéctate al contenedor:

bash
docker exec -it ollama ollama pull llama2
docker exec -it ollama ollama pull mistral
docker exec -it ollama ollama pull codellama
Backups
bash
# Backup de PostgreSQL
docker exec postgres pg_dump -U admin multiapp_db > backup.sql

# Backup de volúmenes
docker run --rm -v mi-proyecto-docker_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_backup.tar.gz /data
🐛 Troubleshooting
Problemas Comunes
Puertos en uso: Cambiar puertos en docker-compose.yml
Memoria insuficiente: Reducir servicios o aumentar recursos
Permisos: Verificar que Docker tenga permisos necesarios
Logs Útiles
bash
# Ver logs de todos los servicios
docker-compose logs

# Logs de un servicio específico
docker-compose logs evolution-api
docker-compose logs n8n
docker-compose logs ollama
📄 Licencias
Evolution API: Consultar repositorio oficial
n8n: Fair-code distributed license
Ollama: MIT License
PostgreSQL: PostgreSQL License
Redis: BSD License
🤝 Contribuir
Fork el proyecto
Crear feature branch (git checkout -b feature/AmazingFeature)
Commit cambios (git commit -m 'Add some AmazingFeature')
Push a la branch (git push origin feature/AmazingFeature)
Abrir Pull Request
📞 Soporte
Para soporte técnico:

Abrir issue en GitHub
Consultar documentación oficial de cada servicio
Verificar logs de contenedores
¡Listo para usar! 🚀


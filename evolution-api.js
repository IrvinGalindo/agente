// Wrapper para Evolution API usando la imagen oficial como base
const { spawn } = require('child_process');
const express = require('express');
const httpProxy = require('http-proxy-middleware');
const Docker = require('dockerode');

const app = express();
const PORT = 8080;

console.log('🚀 Iniciando Evolution API Wrapper...');

// Función para verificar si Docker está disponible
async function checkDocker() {
    try {
        const docker = new Docker();
        await docker.ping();
        return true;
    } catch (error) {
        console.log('⚠️  Docker no disponible, usando modo standalone');
        return false;
    }
}

// Función para iniciar Evolution API en contenedor Docker
async function startEvolutionAPIDocker() {
    try {
        const docker = new Docker();
        
        const container = await docker.createContainer({
            Image: 'atendai/evolution-api:latest',
            ExposedPorts: {
                '8080/tcp': {}
            },
            PortBindings: {
                '8080/tcp': [{ HostPort: '8081' }]
            },
            Env: [
                `SERVER_TYPE=${process.env.SERVER_TYPE || 'https'}`,
                `SERVER_PORT=8080`,
                `SERVER_URL=${process.env.SERVER_URL}`,
                `AUTHENTICATION_API_KEY=${process.env.AUTHENTICATION_API_KEY}`,
                `DATABASE_ENABLED=${process.env.DATABASE_ENABLED || 'false'}`,
                `DATABASE_PROVIDER=${process.env.DATABASE_PROVIDER || 'postgresql'}`,
                `DATABASE_CONNECTION_URI=${process.env.DATABASE_CONNECTION_URI}`,
                `DATABASE_CONNECTION_DB_PREFIX_NAME=${process.env.DATABASE_CONNECTION_DB_PREFIX_NAME}`,
                `CACHE_REDIS_ENABLED=${process.env.CACHE_REDIS_ENABLED || 'true'}`,
                `CACHE_REDIS_URI=${process.env.CACHE_REDIS_URI}`,
                `CACHE_REDIS_PREFIX_KEY=${process.env.CACHE_REDIS_PREFIX_KEY || 'evolution'}`,
                `CONFIG_SESSION_PHONE_VERSION=${process.env.CONFIG_SESSION_PHONE_VERSION}`,
                `LOG_LEVEL=${process.env.LOG_LEVEL || 'ERROR'}`,
                `LANGUAGE=${process.env.LANGUAGE || 'es'}`,
                `CORS_ORIGIN=${process.env.CORS_ORIGIN || '*'}`,
                `CORS_METHODS=${process.env.CORS_METHODS || 'POST,GET,PUT,DELETE'}`,
                `CORS_CREDENTIALS=${process.env.CORS_CREDENTIALS || 'true'}`
            ]
        });

        await container.start();
        console.log('✅ Evolution API iniciado en Docker');
        
        // Proxy todas las requests al contenedor Docker
        app.use('/', httpProxy.createProxyMiddleware({
            target: 'http://localhost:8081',
            changeOrigin: true,
            logLevel: 'silent'
        }));
        
        return true;
    } catch (error) {
        console.error('❌ Error iniciando Evolution API en Docker:', error.message);
        return false;
    }
}

// Función fallback - servidor Express simple con endpoints básicos
function startEvolutionAPIFallback() {
    console.log('🔄 Iniciando Evolution API en modo fallback...');
    
    app.use(express.json());
    
    // Endpoint básico de health check
    app.get('/', (req, res) => {
        res.json({
            status: 'online',
            message: 'Evolution API Fallback Mode',
            version: '1.0.0',
            mode: 'fallback'
        });
    });
    
    // Endpoint de instancias
    app.get('/instance/fetchInstances', (req, res) => {
        res.json({
            status: 'success',
            instances: [],
            message: 'No instances in fallback mode'
        });
    });
    
    // Endpoint para crear instancia
    app.post('/instance/create', (req, res) => {
        res.json({
            status: 'error',
            message: 'Instance creation not available in fallback mode',
            suggestion: 'Please configure full Evolution API deployment'
        });
    });
    
    // Endpoint de manager
    app.get('/manager/fetchInstances', (req, res) => {
        res.json({
            status: 'success',
            instances: [],
            message: 'Manager endpoint - fallback mode'
        });
    });
    
    // Middleware de autenticación básica
    app.use((req, res, next) => {
        const apiKey = req.headers['apikey'] || req.query.apikey;
        const expectedKey = process.env.AUTHENTICATION_API_KEY;
        
        if (!apiKey || apiKey !== expectedKey) {
            return res.status(401).json({
                status: 'error',
                message: 'Unauthorized - Invalid API Key'
            });
        }
        
        next();
    });
    
    // Catch-all para endpoints no implementados
    app.all('*', (req, res) => {
        res.status(501).json({
            status: 'error',
            message: 'Endpoint not implemented in fallback mode',
            endpoint: req.path,
            method: req.method,
            suggestion: 'This feature requires full Evolution API deployment'
        });
    });
}

// Función principal
async function main() {
    console.log('📋 Configuración Evolution API:');
    console.log('- SERVER_URL:', process.env.SERVER_URL);
    console.log('- DATABASE_ENABLED:', process.env.DATABASE_ENABLED);
    console.log('- CACHE_REDIS_ENABLED:', process.env.CACHE_REDIS_ENABLED);
    console.log('- AUTHENTICATION_API_KEY:', process.env.AUTHENTICATION_API_KEY ? '✅ Configurado' : '❌ Faltante');
    
    // Verificar si Docker está disponible
    const dockerAvailable = await checkDocker();
    
    if (dockerAvailable) {
        // Intentar usar Docker
        const dockerStarted = await startEvolutionAPIDocker();
        if (!dockerStarted) {
            startEvolutionAPIFallback();
        }
    } else {
        // Usar modo fallback
        startEvolutionAPIFallback();
    }
    
    // Iniciar servidor
    app.listen(PORT, '0.0.0.0', () => {
        console.log(`✅ Evolution API corriendo en puerto ${PORT}`);
        console.log(`🔗 URL: http://0.0.0.0:${PORT}`);
    });
    
    // Manejo de errores
    process.on('uncaughtException', (error) => {
        console.error('❌ Error no capturado:', error);
    });
    
    process.on('unhandledRejection', (reason, promise) => {
        console.error('❌ Promesa rechazada:', reason);
    });
}

// Iniciar aplicación
main().catch(error => {
    console.error('❌ Error fatal:', error);
    process.exit(1);
});

module.exports = app;

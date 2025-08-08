const express = require('express');
const cors = require('cors');
const axios = require('axios');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434';

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Ruta principal - servir HTML
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API Routes
app.get('/api/models', async (req, res) => {
    try {
        const response = await axios.get(`${OLLAMA_URL}/api/tags`);
        res.json(response.data);
    } catch (error) {
        console.error('Error fetching models:', error.message);
        res.status(500).json({ error: 'No se pudo conectar con Ollama', details: error.message });
    }
});

app.post('/api/pull', async (req, res) => {
    const { model } = req.body;
    
    // Lista de modelos permitidos para cuentas gratuitas
    const allowedModels = [
        'tinyllama',
        'tinyllama:1.1b',
        'tinyllama:1.1b-chat-q4_0',
        'qwen2:0.5b',
        'phi3:mini-4k',
        'gemma:2b'
    ];
    
    if (!allowedModels.some(allowed => model.includes(allowed.split(':')[0]))) {
        return res.status(400).json({ 
            error: 'Modelo no permitido en plan gratuito',
            allowed: allowedModels
        });
    }
    
    try {
        // Iniciar descarga
        const response = await axios.post(`${OLLAMA_URL}/api/pull`, { name: model });
        res.json({ message: `Instalando ${model}...`, status: 'started' });
    } catch (error) {
        console.error('Error pulling model:', error.message);
        res.status(500).json({ error: 'Error instalando modelo', details: error.message });
    }
});

app.post('/api/generate', async (req, res) => {
    const { model = 'tinyllama', prompt, stream = false } = req.body;
    
    try {
        const response = await axios.post(`${OLLAMA_URL}/api/generate`, {
            model,
            prompt,
            stream
        });
        res.json(response.data);
    } catch (error) {
        console.error('Error generating text:', error.message);
        res.status(500).json({ error: 'Error generando texto', details: error.message });
    }
});

app.get('/api/status', async (req, res) => {
    try {
        const response = await axios.get(`${OLLAMA_URL}/api/tags`);
        res.json({ status: 'online', models: response.data?.models?.length || 0 });
    } catch (error) {
        res.status(500).json({ status: 'offline', error: error.message });
    }
});

// Manejo de errores global
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Algo salió mal!' });
});

app.listen(PORT, () => {
    console.log(`🚀 Ollama Manager corriendo en puerto ${PORT}`);
    console.log(`📡 Conectando a Ollama en: ${OLLAMA_URL}`);
});
const express = require('express');
const app = express();

app.get('/', (req, res) => {
    res.json({
        message: 'Bienvenue sur l\'application DevSecOps TP',
        version: '1.0'
    });
});

app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'ok',
        timestamp: new Date().toISOString()
    });
});

module.exports = app;
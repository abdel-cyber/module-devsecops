// ✅ BONNE PRATIQUE : Utiliser les variables d'environnement pour les secrets
// Ce fichier montre comment gérer correctement les secrets/clés API

// Récupération depuis les variables d'environnement
const API_KEY = process.env.API_KEY || '';

// Validation en production
if (!API_KEY && process.env.NODE_ENV === 'production') {
    console.error('❌ ERREUR : API_KEY doit être définie dans les variables d\'environnement');
    throw new Error('API_KEY must be set in environment variables');
}

// Affichage sécurisé (ne jamais logger la clé complète)
if (API_KEY) {
    console.log('✅ API_KEY configurée :', API_KEY.substring(0, 5) + '***');
} else {
    console.log('⚠️  API_KEY non configurée (mode développement)');
}

module.exports = {
    apiKey: API_KEY,
    // Configuration pour les services externes
    serviceConfig: {
        apiKey: API_KEY,
        timeout: 5000,
        retries: 3
    }
};

// Documentation :
// - En LOCAL : définir API_KEY dans le fichier .env
// - En GITLAB CI : définir API_KEY dans Settings > CI/CD > Variables (masked)
// - En AWS/Azure : utiliser les variables d'environnement du service
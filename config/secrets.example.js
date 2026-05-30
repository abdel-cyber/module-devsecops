// NOTE: Ce fichier est un EXEMPLE de mauvaise pratique
// Il sera utilisé pour la démonstration du scan de sécurité
// NE PAS UTILISER en production !

// ❌ MAUVAISE PRATIQUE : Secret en dur dans le code
// const API_KEY = "votre-cle-api-ici"; // NE JAMAIS mettre de vraies clés ici !

// ✅ BONNE PRATIQUE : Utiliser les variables d'environnement
const API_KEY = process.env.API_KEY || '';

// Vérifier que la clé est définie en production
if (!API_KEY && process.env.NODE_ENV === 'production') {
    console.error('ERREUR : API_KEY doit être définie dans les variables d\'environnement');
    throw new Error('API_KEY must be set in environment variables');
}

module.exports = {
    apiKey: API_KEY,
    // Autres configurations...
};
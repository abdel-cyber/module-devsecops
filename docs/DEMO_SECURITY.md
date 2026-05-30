# Démonstration pédagogique : Détection de secrets

## 🎯 Objectif

Démontrer le fonctionnement du stage `security` du pipeline GitLab CI/CD qui détecte les secrets exposés dans le code.

## ⚠️ ATTENTION

**N'utiliser QUE des faux secrets pour cette démonstration !**
- Exemple de faux secret : `API_KEY=sk-demo-123456789`
- JAMAIS de vraies clés API ou tokens

## 📝 Procédure de démonstration

### Étape 1 : Injection d'un faux secret (ÉCHEC attendu)

1. **Créer un fichier de configuration factice** (ou modifier `src/app.js`) :
   
   Créer `config/secrets.js` avec :
   ```javascript
   // FAUX SECRET - POUR DÉMONSTRATION UNIQUEMENT
   const API_KEY = "sk-demo-123456789";
   
   module.exports = {
     apiKey: API_KEY
   };
   ```

2. **Commiter et pousser** :
   ```bash
   git add config/secrets.js
   git commit -m "test: ajout faux secret pour démonstration"
   git push origin develop
   ```

3. **Résultat attendu** :
   - Le pipeline s'exécute
   - Stage `test` : ✅ Succès
   - Stage `security` : ❌ **ÉCHEC** avec message :
     ```
     ❌ ERREUR : Secret ou faux secret détecté (API_KEY=sk-...).
        Les clés API ne doivent JAMAIS être dans le code source.
        Utilisez les variables d'environnement ou GitLab CI/CD Variables.
     ```
   - Les stages suivants ne s'exécutent pas (pipeline bloqué)

### Étape 2 : Correction (SUCCÈS attendu)

1. **Supprimer le faux secret** et remplacer par des variables d'environnement :
   
   Modifier `config/secrets.js` :
   ```javascript
   // Bonne pratique : utiliser les variables d'environnement
   const API_KEY = process.env.API_KEY || '';
   
   if (!API_KEY && process.env.NODE_ENV === 'production') {
     throw new Error('API_KEY must be set in environment variables');
   }
   
   module.exports = {
     apiKey: API_KEY
   };
   ```

2. **Documenter dans le README** :
   ```markdown
   ## Configuration des secrets
   
   Les secrets doivent être configurés dans :
   - **Développement local** : fichier `.env` (non versionné)
   - **GitLab CI/CD** : Settings → CI/CD → Variables (masked)
   - **Production** : Variables d'environnement du service cloud
   
   Exemple `.env` :
   ```
   API_KEY=votre-clé-ici
   ```
   ```

3. **Commiter et pousser** :
   ```bash
   git add config/secrets.js README.md
   git commit -m "fix: correction - utilisation variables d'environnement pour secrets"
   git push origin develop
   ```

4. **Résultat attendu** :
   - Le pipeline s'exécute
   - Stage `test` : ✅ Succès
   - Stage `security` : ✅ **Succès** avec message :
     ```
     ✅ Aucun secret suspect détecté. Scan terminé avec succès.
     ```
   - Stage `build` : ✅ Succès (image construite et poussée)
   - Stage `deploy_staging` : ✅ Succès (si sur branche develop)

## 🔍 Patterns détectés par le scan

Le job `security` recherche les patterns suivants :

1. **Clés API** : `API_KEY\s*=\s*["']?sk-[a-zA-Z0-9-]+`
   - Exemples détectés :
     - `API_KEY=sk-demo-123`
     - `API_KEY="sk-prod-abc123"`
     - `const API_KEY = 'sk-test-xyz789'`

2. **Mots de passe** (warning) : `(password|passwd|pwd)\s*=\s*["'][^"']{3,}`
   - Exemples :
     - `password="monMotDePasse"`
     - `DB_PASSWD='secret123'`

## 📊 Points à vérifier dans GitLab

1. **Pipeline → Jobs** :
   - Cliquer sur le job `security` pour voir les logs
   - Message d'erreur détaillé en cas de détection
   - Liste des lignes problématiques

2. **Container Registry** (après correction) :
   - Deploy → Container Registry
   - Vérifier la présence des tags (SHA + latest)

3. **Variables CI/CD** :
   - Settings → CI/CD → Variables
   - Ajouter les vrais secrets ici (type: Variable, masked)

## 🎓 Bonne pratiques apprises

✅ **À FAIRE** :
- Utiliser `process.env.VARIABLE` pour les secrets
- Stocker les secrets dans GitLab CI/CD Variables (masked)
- Ajouter `.env` au `.gitignore`
- Fournir un `.env.example` avec des valeurs factices
- Utiliser des secret managers en production (AWS Secrets Manager, Azure Key Vault)

❌ **À NE JAMAIS FAIRE** :
- Commiter des secrets en dur dans le code
- Commiter des fichiers `.env` contenant des vrais secrets
- Partager des tokens dans les messages de commit
- Exposer des credentials dans les logs

## 🛠️ Outils de scan de secrets professionnels

Pour aller plus loin, des outils dédiés existent :

- **GitGuardian** : Scan continu des repos
- **TruffleHog** : Détection de secrets dans l'historique Git
- **git-secrets** : Hook Git local
- **detect-secrets** : Outil Python de Yelp
- **Gitleaks** : Scanner de secrets léger et rapide

## 📸 Captures attendues pour le livrable

1. **Pipeline en échec** (job security rouge)
2. **Logs du job security** montrant le secret détecté
3. **Pipeline corrigé** (tous les jobs verts)
4. **Container Registry** avec les images taguées

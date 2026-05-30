# Image de base : Node.js 20 (LTS)
FROM node:20-alpine

# Répertoire de travail dans le conteneur
WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances (production uniquement)
RUN npm ci --only=production

# Copier le code source (y compris src/)
COPY . .

# Port exposé par l'application
EXPOSE 3000

# Variable d'environnement par défaut
ENV PORT=3000

# Point d'entrée : lancer le serveur Node
CMD ["node", "src/server.js"]

# VPS NestFind — Informations de connexion

## Fournisseur
- **Société** : LWS (Ligne Web Services)
- **Adresse** : 10 rue Penthièvre, 75008 Paris, France
- **Site** : https://www.lws.fr
- **Support technique** : https://aide.lws.fr

## Paramètres SSH
- **Hostname** : `vps123057.serveur-vps.net`
- **Adresse IP** : `185.98.128.123`
- **Utilisateur** : `root`
- **Mot de passe** : `vfZeEJTY5Fz`

## Déploiement NestFind sur le VPS
- **Dossier d'installation** : `/opt/nestfind`
- **Backend** : Node.js + Express + PostgreSQL
- **Base de données** : PostgreSQL `immo_db`
- **Process manager** : PM2 (process: `nestfind-api`)
- **Backend port interne** : `5001`
- **Port public Nginx** : `3001`
- **Reverse proxy** : Nginx
  - `/api/*` → backend
  - `/socket.io/*` → backend (WebSocket)

## Commandes de mise à jour
```bash
ssh root@185.98.128.123
cd /opt/nestfind
git pull origin main
npm install --production
pm2 restart nestfind-api
```

## Frontend
- **Hébergement** : Vercel
- **URL** : https://neststayy.vercel.app/
- **Déploiement** : automatique sur push `main`

## Repos GitHub
- `bariszgravigravine-maker/projet-de-memoire` (origin)
- `jacquesngono-art/projet-de-memoire` (jacques) — **repo connecté à Vercel**

## Tokens GitHub
- **bariszgravigravine-maker** : `REMPLACER_TOKEN_GITHUB_1`
- **uniquement pour le projet MyKOG** : [voir gestionnaire de secrets]

## Important
- Vercel déploie depuis `jacquesngono-art/projet-de-memoire`
- Toujours pousse- **jacquesngono-art** : `REMPLACER_TOKEN_GITHUB_2`
r sur les deux remotes : `git push origin main && git push jacques main`

## Branches
- `main` : branche de production (Vercel + VPS déploient depuis `main`)
- `carte-3D` : branche de la carte 3D (optimisations MapLibre : workers, cache tuiles, preconnect) — créée le 20/09/2026, présente sur les 2 remotes (origin + jacques)
  - NB : Git n'autorise pas les espaces dans les noms de branches, "carte 3D" → `carte-3D`

## Comptes de test seedés
- `admin@immo.cm` / `admin123`
- `agent@immo.cm` / `agent123`
- `ndongo@immo.cm` / `agent123`
- `aisha.toumba@immo.cm` / `agent123`
- `sandrine.foka@immo.cm` / `agent123`
- `user@immo.cm` / `user123`

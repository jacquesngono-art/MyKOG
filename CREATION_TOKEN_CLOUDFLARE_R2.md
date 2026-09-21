# Création du Token API Cloudflare pour R2

## Étape 1 : Connexion au dashboard Cloudflare

1. Va sur [https://dash.cloudflare.com](https://dash.cloudflare.com)
2. Connecte-toi avec ton compte Cloudflare

## Étape 2 : Création du Token API

1. Va sur [https://dash.cloudflare.com/profile/api-tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Clique sur le bouton bleu **"Create Token"** (en haut à droite)

## Étape 3 : Utiliser le template R2

1. Dans la section **"API Token Templates"**, cherche le template **"Edit Cloudflare R2"**
2. Clique sur le bouton **"Use template"** à droite de ce template

## Étape 4 : Configuration du token

Les champs sont pré-remplis avec le template. Vérifie juste :

- **Permissions** :
  - `R2` → `Edit` ✅ (déjà configuré)
- **Account Resources** :
  - `Include` → `Specific account` → sélectionne ton compte MyKOG
- **Client IP Address Filtering** : laisse vide (ou mets ton IP si tu veux restreindre)
- **TTL (Time to Live)** : laisse **"Never Expire"** (ou mets une date si tu préfères)

## Étape 5 : Finaliser

1. Clique sur le bouton vert **"Continue to summary"** en bas
2. Vérifie le résumé
3. Clique sur **"Create Token"**
4. **IMPORTANT : Copie le token tout de suite !** Il ne sera plus jamais affiché. Il ressemble à :
   ```
   oDOiNTxNvU4Fn5vabc123def456ghij789klmno
   ```
5. Colle-le dans le fichier `.env` de `backend-API/` :
   ```
   CLOUDFLARE_API_TOKEN=oDOiNTxNvU4Fn5vabc123def456ghij789klmno
   ```

## Test

Une fois le token ajouté au `.env`, redémarre le serveur et les uploads iront directement vers R2 via l'API Cloudflare (qui fonctionne depuis n'importe quel environnement).

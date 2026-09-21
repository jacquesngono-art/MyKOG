# Mes retenons — Problèmes rencontrés

## 1. Erreur HTTP 401 au téléchargement de PDF depuis Cloudinary

### Contexte
L'application de bureau Electron (`desktop-app`) permet de visualiser des PDFs de résumés de textes stockés sur **Cloudinary** (resource_type: `raw`). Au clic sur une carte de résumé, l'app télécharge le PDF via `net.request()` (Electron) puis l'affiche dans une `BrowserWindow`.

### Problème
```
Erreur téléchargement PDF: Error: HTTP 401
    at ClientRequest.<anonymous> (main.js:237)
```

Cloudinary retournait un **HTTP 401 Unauthorized** systématiquement pour tous les PDFs.

### Cause racine
L'API Cloudinary pour les ressources **raw** (PDF) exige un en-tête HTTP `User-Agent` valide pour servir le fichier. Electron `net.request()` n'envoie **aucun User-Agent par défaut**, contrairement à :

- Un navigateur web → envoie `Mozilla/5.0 ...`
- Flutter `http.get()` → envoie `Dart/<version>`
- Node.js `https.get()` → envoie `Node/<version>` + `User-Agent` de la lib HTTP

Cloudinary interprète l'absence de `User-Agent` comme une requête automatisée non autorisée et refuse avec un **401**.

### Première tentative (échec)
Ajout d'un `User-Agent` via les `headers` de `net.request()` :
```js
const request = net.request({
  url,
  headers: {
    'User-Agent': 'Mozilla/5.0 ...'
  }
});
```
**Résultat** : toujours 401. La stack réseau Chromium d'Electron (`net.request`) a un comportement différent de Node.js natif — elle ne gère pas correctement les headers customs pour certains types de contenus.

### Solution retenue
Remplacer `net.request()` par le module **`https` natif de Node.js** :

```js
const https = require('https');

// Avant (ne marchait pas)
const request = net.request(url);

// Après (fonctionne)
https.get(url, (response) => { ... });
```

Le module `https` de Node.js envoie un `User-Agent` par défaut (`Node/<version>`) accepté par Cloudinary, et le comportement HTTP est standard et prévisible.

### Fichiers modifiés
- `desktop-app/main.js` : import de `https` + remplacement de `net.request()` par `https.get()`

### Leçon à retenir
- **`net.request` d'Electron** est à éviter pour les téléchargements HTTP simples — il utilise la stack Chromium (différente de Node.js) et peut rejeter certaines requêtes ou mal gérer les headers.
- **Préférer `https.get()` de Node.js** pour les téléchargements de fichiers dans le main process Electron.
- Cloudinary est sensible aux en-têtes HTTP pour les ressources `raw` (PDF) — toujours vérifier que le `User-Agent` est présent.

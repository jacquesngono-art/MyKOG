#!/bin/bash

# Script d'installation de Nginx avec module RTMP pour streaming
# Compatible avec Ubuntu/Debian

set -e

echo "🚀 Installation de Nginx avec module RTMP..."

# Vérifier si on est root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Veuillez exécuter ce script en tant que root (sudo)"
    exit 1
fi

# Mettre à jour les paquets
echo "📦 Mise à jour des paquets..."
apt-get update

# Installer les dépendances
echo "📦 Installation des dépendances..."
apt-get install -y \
    build-essential \
    libpcre3-dev \
    libssl-dev \
    zlib1g-dev \
    libnginx-mod-rtmp \
    nginx \
    git

# Créer le répertoire pour les fichiers HLS
echo "📁 Création du répertoire HLS..."
mkdir -p /var/www/html/hls
chown -R www-data:www-data /var/www/html/hls
chmod -R 755 /var/www/html/hls

# Copier la configuration Nginx
echo "⚙️ Configuration de Nginx..."
if [ -f "nginx.conf" ]; then
    cp nginx.conf /etc/nginx/nginx.conf
    echo "✅ Configuration copiée"
else
    echo "⚠️ Fichier nginx.conf non trouvé dans le répertoire actuel"
    echo "📝 Création de la configuration manuelle..."
    
    # Créer la configuration RTMP
    cat > /etc/nginx/modules-enabled/rtmp.conf << 'EOF'
load_module modules/ngx_rtmp_module.so;
EOF

    # Ajouter la configuration RTMP au nginx.conf existant
    if ! grep -q "rtmp {" /etc/nginx/nginx.conf; then
        # Sauvegarder la config existante
        cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
        
        # Ajouter la config RTMP avant le bloc http
        sed -i '/^http {/i rtmp {\n    server {\n        listen 1935;\n        chunk_size 4096;\n        allow publish all;\n        allow play all;\n        application live {\n            live on;\n            record off;\n            hls on;\n            hls_path /var/www/html/hls;\n            hls_fragment 2s;\n            hls_playlist_length 10s;\n            hls_continuous on;\n            hls_cleanup on;\n            hls_nested on;\n        }\n    }\n}\n' /etc/nginx/nginx.conf
    fi
fi

# Ajouter la configuration HTTP pour HLS si elle n'existe pas
if [ ! -f "/etc/nginx/sites-available/hls" ]; then
    cat > /etc/nginx/sites-available/hls << 'EOF'
server {
    listen 8080;
    server_name localhost;

    location /hls {
        types {
            application/vnd.apple.mpegurl m3u8;
            video/mp2t ts;
        }
        root /var/www/html;
        add_header 'Cache-Control' 'no-cache';
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;

        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }
}
EOF

    ln -sf /etc/nginx/sites-available/hls /etc/nginx/sites-enabled/hls
fi

# Tester la configuration
echo "🔍 Test de la configuration Nginx..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration valide"
    
    # Redémarrer Nginx
    echo "🔄 Redémarrage de Nginx..."
    systemctl restart nginx
    systemctl enable nginx
    
    echo ""
    echo "✅ Installation terminée avec succès !"
    echo ""
    echo "📋 Informations importantes :"
    echo "   - Port RTMP: 1935"
    echo "   - Port HTTP HLS: 8080"
    echo "   - URL RTMP: rtmp://VOTRE_IP:1935/live/STREAM_KEY"
    echo "   - URL HLS: http://VOTRE_IP:8080/hls/STREAM_KEY/index.m3u8"
    echo ""
    echo "🔧 Pour vérifier que Nginx fonctionne :"
    echo "   sudo systemctl status nginx"
    echo ""
    echo "📝 Pour voir les logs :"
    echo "   sudo tail -f /var/log/nginx/error.log"
    echo ""
else
    echo "❌ Erreur dans la configuration Nginx"
    echo "📝 Vérifiez les logs : sudo tail -f /var/log/nginx/error.log"
    exit 1
fi


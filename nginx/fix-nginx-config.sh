#!/bin/bash

# Script pour supprimer les directives add_header du bloc RTMP

echo "🔧 Correction de la configuration Nginx..."

# Créer une sauvegarde
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)

# Supprimer les lignes add_header du bloc RTMP (lignes 48-50)
sudo sed -i '/^[[:space:]]*# CORS pour permettre l'accès depuis l'app/,/^[[:space:]]*add_header.*always;$/d' /etc/nginx/nginx.conf

# Vérifier qu'il ne reste plus d'add_header dans le bloc RTMP (avant la ligne 51)
if grep -n "add_header" /etc/nginx/nginx.conf | grep -v "location /hls" | gre
p -v "^[5-9]"; then
    echo "⚠️ Il reste encore des directives add_header dans le bloc RTMP"
    echo "Suppression manuelle nécessaire..."
    # Supprimer toutes les lignes add_header avant la ligne 51
    sudo sed -i '1,50{/add_header/d}' /etc/nginx/nginx.conf
fi

echo "✅ Configuration corrigée"
echo "🧪 Test de la configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration valide !"
    echo "🔄 Redémarrage de Nginx..."
    sudo systemctl restart nginx
    echo "✅ Nginx redémarré"
else
    echo "❌ Erreur dans la configuration"
    echo "📝 Vérifiez les logs : sudo tail -20 /var/log/nginx/error.log"
fi


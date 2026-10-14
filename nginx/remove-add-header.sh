#!/bin/bash

# Script pour supprimer les directives add_header du bloc RTMP

echo "🔧 Suppression des directives add_header du bloc RTMP..."

# Sauvegarder le fichier
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# Supprimer les lignes 47-50 (commentaire CORS + 3 lignes add_header)
sudo sed -i '47,50d' /etc/nginx/nginx.conf

echo "✅ Lignes supprimées"
echo "🧪 Test de la configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Configuration valide !"
    echo "🔄 Redémarrage de Nginx..."
    sudo systemctl restart nginx
    echo "✅ Nginx redémarré avec succès"
    echo ""
    echo "📊 Vérification des ports..."
    sudo ss -tuln | grep -E '1935|8080'
else
    echo "❌ Erreur dans la configuration"
fi


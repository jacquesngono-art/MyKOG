#!/bin/bash
# Script de test : upload 25 enseignements (images aléatoires répétées + 1 audio unique)
API="http://185.98.128.123:3001/mykog-api/api/enseignements"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIO="$DIR/les batailles spirituelles.aac"
TOTAL=25

# --- Images disponibles (choisies aléatoirement avec répétition) ---
IMAGES=(
  "515066649_746077851487013_6549721628094458653_n.jpg"
  "559526104_822298410531623_688005464575744551_n.jpg"
  "589649829_1266655832166405_3509182321465235945_n.jpg"
  "592891265_870059112422219_3091511982139619413_n.jpg"
  "602015097_884809187613878_4080439313023648247_n.jpg"
  "Bible_Study_Group_Prayer_null_1762634762071.jpg"
  "Christian_Cross_Golden_Light_null_1762634761366.jpg"
  "Christian_Pastor_Teaching_Bible_null_1762634759386.jpg"
  "Christian_Youth_Worship_null_1762634762997.jpg"
  "Church_Worship_Contemporary_null_1762634760147.jpg"
  "Gospel_Choir_Christian_Music_null_1762634758556.jpg"
  "rain-portrait-1.png"
  "rain-portrait-2.png"
  "rain-portrait-3.png"
  "rain-portrait-4.png"
  "rain-portrait-5.png"
  "teaching_1.jpg"
  "téléchargement.jpg"
)

# --- Contenus inventés ---
TITLES=(
  "La Puissance de la Prière"
  "Marcher dans la Foi"
  "L'Amour qui Transforme"
  "La Grâce qui Suffit"
  "Les Fondations Spirituelles"
  "Vaincre par la Louange"
  "La Paix au Milieu de la Tempête"
  "Le Secret de la Persévérance"
  "Fidélité et Alliance"
  "La Richesse de la Sagesse"
  "Une Vie de Prière Intense"
  "L'Héritage des Justes"
  "Le Combat de la Foi"
  "La Restauration Divine"
  "Les Joyaux du Royaume"
  "Gravir la Montagne de Dieu"
  "L'autorité du Croyant"
  "Des Racines Profondes"
  "La Tempête et la Direction de Dieu"
  "La Puissance de l'Intercession"
  "Les Promesses Éternelles"
  "La Victoire de l'Agneau"
  "Discerner les Temps"
  "La Joie qui Fortifie"
  "La Paix et la Confiance"
)
SPEAKERS=( "Pasteur Jean" "Pasteur Cyrille" "Pasteur Sarah" "Apôtre David" "Évangéliste Marc" "Prophète Élie" "Pasteure Ruth" "Diacre Paul" )
CATEGORIES=( "Foi" "Prière" "Louange" "Enseignement" "Prophétique" "Adoration" )
TYPE_CULTES=( "Culte d'Impact" "Culte Prophétique" "Culte d'Enseignement" "Conférence" "Séminaire" )
DESCRIPTIONS=(
  "Un enseignement puissant pour fortifier votre foi au quotidien."
  "Découvrez comment marcher par la foi victorieusement."
  "L'amour de Dieu révélé comme fondement de toute vie."
  "La grâce suffisante pour chaque saison de votre vie."
)
TAGSETS=("foi,pouvoir,gloire" "prière,spirituel" "louange,adoration" "enseignement,biblique" "prophétique,révélation" "victoire,courage")

# --- Helper random ---
pick() { local arr=("$@"); echo "${arr[$((RANDOM % ${#arr[@]}))]}"; }

MOIS_NAMES=("Janvier" "Février" "Mars" "Avril" "Mai" "Juin" "Juillet" "Août" "Septembre" "Octobre" "Novembre" "Décembre")

# --- Compteurs ---
ok=0; fail=0
for i in $(seq 1 $TOTAL); do
  IMG="$(pick "${IMAGES[@]}")"
  FILE="$DIR/$IMG"
  TITLE="${TITLES[$((i-1))]}"
  SPEAKER="$(pick "${SPEAKERS[@]}")"
  CATEGORY="$(pick "${CATEGORIES[@]}")"
  TYPE="$(pick "${TYPE_CULTES[@]}")"
  DESC="$(pick "${DESCRIPTIONS[@]}")"
  TAGS="$(pick "${TAGSETS[@]}")"
  MOIS="${MOIS_NAMES[$(( (RANDOM % 12) + 1 - 1 ))]}"
  ANNEE=$(( (RANDOM % 4) + 2023 ))
  DUREE=$(( (RANDOM % 5400 ) + 900 ))

  echo "[$i/$TOTAL] Upload de: $TITLE — $SPEAKER — $CATEGORY ($TYPE) mo$MOIS/$ANNEE — img: $IMG"
  RESP=$(curl -s -m 600 -X POST "$API" \
    -F "image=@$FILE" \
    -F "audio=@$AUDIO" \
    -F "title=$TITLE" \
    -F "speaker=$SPEAKER" \
    -F "category=$CATEGORY" \
    -F "typeCulte=$TYPE" \
    -F "description=$DESC" \
    -F "tags=$TAGS" \
    -F "mois=$MOIS" \
    -F "annee=$ANNEE" \
    -F "duration=$DUREE" 2>&1)
  if echo "$RESP" | grep -q "\"id\""; then
    ID=$(echo "$RESP" | grep -oE '"id":"[^"]+"' | head -1)
    echo "   ✅ OK $ID"
    ok=$((ok+1))
  else
    echo "   ❌ ÉCHEC: $(echo "$RESP" | head -c 200)"
    fail=$((fail+1))
  fi
done

echo "=============================="
echo "Terminé : $ok OK / $fail échecs $TOTAL"
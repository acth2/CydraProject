# Déclarer un tableau pour stocker les lignes
declare -a depsList

# Utiliser awk pour extraire les lignes et les stocker dans le tableau
depsList=($(awk '/%DEPENDS%/ {flag=1; next} flag {print; if (/^$/) exit}' ${DEPENDS_FILE}))

# Afficher les lignes du tableau
for line in "${lines[@]}"; do
    echo "$depsList"
done

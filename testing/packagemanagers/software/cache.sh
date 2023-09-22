# Déclarer un tableau pour stocker les lignes
declare -a lines

# Utiliser awk pour extraire les lignes et les stocker dans le tableau
lines=($(awk '/%DEPENDS%/ {flag=1; next} flag && !/^$/ {print; if (/^$/) exit}' exemple.txt))

# Afficher les lignes du tableau
for line in "${lines[@]}"; do
    echo "$line"
done

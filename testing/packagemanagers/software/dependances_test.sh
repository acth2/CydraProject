# Déclarer un tableau pour stocker les lignes
declare -a lines
flag0 = 0
# Utiliser awk pour extraire les lignes et les stocker dans le tableau
while read -r line; do
    lines+=("$line")
    if [[ "$line" == *"%*"* ]]; then
        break
    fi
    if [[ "$line" == "%MAKEDEPENDS%" ]]; then
        break
        flag0 = 1
    fi
done < <(awk '/%DEPENDS%/ {flag=1; next} flag && !/^$/ {print; if (/^$/) exit}' $DEPENDS_INFO)

# Afficher les lignes du tableau
for line in "${lines[@]}"; do
    echo "$line"
    if [[ "$flag0" == "0" ]]; then
        echo "$line"
        cydramanager install $line --without-printing-log --without-registering-var --add-as-depends
    fi
done

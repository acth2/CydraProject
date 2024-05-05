declare -a lines
flag0 = 0

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

for line in "${lines[@]}"; do
    echo "$line"
    if [[ "$flag0" == "0" ]]; then
        echo "$line"
        cydramanager install $line --without-printing-log --without-registering-var --add-as-depends
    fi
done

declare -a lines2
flag1 = 0

while read -r line3; do
    lines2+=("$line3")
    if [[ "$line3" == *"%*"* ]]; then
        break
    fi
    if [[ "$line3" == "%MAKEDEPENDS%" ]]; then
        break
        flag1 = 1
    fi
done < <(awk '/%OPTDEPENDS%/ {flag=1; next} flag && !/^$/ {print; if (/^$/) exit}' $DEPENDS_INFO)

for line in "${lines2[@]}"; do
    echo "$line3"
    if [[ "$flag1" == "0" ]]; then
        echo "$line3"
        cydramanager install $line3 --without-printing-log --without-registering-var --add-as-depends
    fi
done

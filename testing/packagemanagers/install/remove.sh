GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m'

function remove {
   echo -e "${GREEN}Supression du gestionnaire de packets..${NC}"
   sleep 1
   echo -e "${GREEN}Supression des fichiers principaux${NC}"
   rm -rf /etc/cydrafetch
   rm -rf /etc/cydramanager
   rm -rf /etc/cydradeps
   rm -rf /etc/cydraterms
   echo -e "${GREEN}Supression du gestionnaire de packet${NC}"
   rm -f /usr/bin/cydramanager
   rm -f /usr/bin/cmar
   rm -f /etc/cydraterms/installedsoftware.list
   echo -e "${GREEN}Le gestionnaire de packet a ete supprimé de votre systeme!${NC}"

if [[ $EUID -ne 0 ]]; then
   if [ "$PRINT_LOG" = true ]; then
    echo -e "${RED}Ce script doit etre execute avec les privileges root${NC}"
    exit 1
   fi
fi

remove

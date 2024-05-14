GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m'

function remove_package {
    if [ "$ADD_AS_DEPS" = false ]; then
        echo -en "${NC}Voulez vous supprimé tout les packets que vous avez installé avec cydramanager? ----- [Y/N]: "
        read asking
        if [[ "${asking}" == "Y" || "${asking}" == "y" ]]; then
            rm -rf /usr/cydramanager
            echo -e "${GREEN}Tout les packets sont supprimés${NC}"
        else 
           echo -e "${NC}Les packets ne seront pas supprimés"
        fi
    fi
}

function remove {
   echo -e "${GREEN}Supression du gestionnaire de packets..${NC}"
   sleep 1
   echo -e "${GREEN}Supression des fichiers principaux${NC}"
   rm -rf /etc/cydrafetch
   rm -rf /etc/cydradeps
   rm -rf /etc/cydraterms
   echo -e "${GREEN}Supression du gestionnaire de packet${NC}"
   rm -f /usr/bin/cydramanager
   remove_package
   echo -e "${GREEN}Le gestionnaire de packet a ete supprimé de votre systeme!${NC}"
}

if [[ $EUID -ne 0 ]]; then
   if [ "$PRINT_LOG" = true ]; then
    echo -e "${RED}Ce script doit etre execute avec les privileges root${NC}"
    exit 1
   fi
fi

remove
exit 0

#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m'

function remove_package {
        echo -en "${NC}Voulez vous supprimé tout les packets que vous avez installez avec cydramanager? ----- [Y/N]: "
        read -r asking
        if [[ "${asking}" == "Y" || "${asking}" == "y" ]]; then
            rm -rf /usr/cydramanager
            echo -e "${GREEN}Tout les packets sont supprimés${NC}"
        else 
           echo -e "${ORANGE}Les packets ne seront pas supprimés${NC}"
        fi
}
function remove {
   echo -e "${GREEN}Supression du gestionnaire de packets..${NC}"
   sleep 1
   echo -e "${GREEN}Supression des fichiers principaux${NC}"
   rm -rf /etc/cydrafetch
   rm -rf /etc/cydradeps
   rm -rf /etc/cydraterms 2> /dev/null
   echo -e "${GREEN}Supression du gestionnaire de packet${NC}"
   rm -f /usr/bin/cydramanager
   remove_package
   echo -e "${GREEN}Le gestionnaire de packet a ete supprimé de votre systeme!${NC}"
}

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Ce script doit etre execute avec les privileges root${NC}"
    exit 1
fi

remove
exit 0

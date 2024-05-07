#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m'

currentDir=$(pwd)
pkglistDir="pm/pkglist"

ENCRYPT=true
INSTALL=false
HELP=false

for arg in "$@"; do
  case "$arg" in
    --install | -install | -i | --i)
      INSTALL=true
      ;;
    --without-encrypt-pm)
      ENCRYPT=false
      ;;
    help)
      HELP=true
  esac
done

function deps_check {
    echo "Recherche des dependances"
    if [ "$ENCRYPT" = true ]; then
        if [ ! -f "/usr/bin/sch" ]; then
            echo -e "${RED}Le logiciel SCH n est pas installé sur votre systeme !\n${ORANGE}Utilisez l'argument --without-encrypt-pm${NC}"
            exit 1
        fi
    fi

    if [ ! -f "/usr/bin/wget" ]; then
        echo -e "${RED}Le logiciel WGET n est pas installer sur votre systeme!\nCe logiciel est obligatoire au bon fonctionnement du gestionnaire de packet, veuillez l installe${NC}"
        exit 1
    fi
}

function install_files {
    mkdir -p /etc/cydrafetch
    mkdir -p /etc/cydradeps
    mkdir -p /etc/cydraterms

    touch /etc/cydrafetch/currentMirror
    touch /etc/cydradeps/installdeps
    touch /etc/cydraterms/outdated.list
    touch /etc/cydraterms/gpt.key
    cp -r ${pkglistDir} /etc/cydraterms/installedsoftware.list
    touch /etc/cydraterms/usersoftware.list
    chmod +rwx /etc/cydraterms/usersoftware.list
    wget "https://raw.githubusercontent.com/acth2/CydraProject/main/packagemanager/changelogs.log" -P /etc/cydraterms --no-check-certificate -q
    wget https://raw.githubusercontent.com/acth2/CydraProject/main/packagemanager/basicmirror.list -P /etc/cydraterms/mainserver.list --no-check-certificate -q

    touch /etc/cydrafetch/1.mirror
    touch /etc/cydrafetch/2.mirror
    touch /etc/cydrafetch/3.mirror
    touch /etc/cydrafetch/4.mirror

}

function write_files {
    echo "http://mir.archlinux.fr" > /etc/cydrafetch/currentMirror

   if [ "$ENCRYPT" = true ]; then
       cd "${currentDir}/pm"
       shc -f cydramanager -o cydramanager2
   fi
}

function start_operation {
    if [ "$HELP" = true ]; then
        echo -e "Programme d'installation de cydramanager:"
        echo -e "      help:                 Ouvre cette commande"
        echo -e "      --without-encrypt-pm: Le gdp pourra etre editer sans etre protegé"
        echo -e "      --install           : Le gdp s'installera "
        exit 0
    fi


    if [ "$INSTALL" = true ]; then
        clear
        echo -e "${GREEN}Installation du gestionnaire de packets ${NC}"
        sleep 3
        clear
        echo -e "${GREEN} -1: Creations des fichiers principaux${NC}"

        install_files

        echo -e "${GREEN} -2: Configuration des fichiers principaux${NC}"

        write_files

        if [ "$ENCRYPT" = true ]; then
            mv "${currentDir}/pm/cydramanager2" /usr/bin/cydramanager
            echo -e "${GREEN} -3: Protection du gestionnaire de packets${NC}"
        else
            mv "${currentDir}/pm/cydramanager" /usr/bin/cydramanager
            echo -e "${ORANGE} -3: Protection du gestionnaire de packets (PASSÉ)${NC}"
        fi
        chmod +rwx /usr/bin/cydramanager

        echo -e "${GREEN} --: Gestionnaire de packet installé${NC}"
        echo -e "${ORANGE}USAGE: sudo cydramanager help${NC}"
        cd ${currentDir}
        exit 0
    else
        echo -e "${ORANGE}Pour commencé l'installation veuillez utilisé l'argument --install !${NC}"
    fi
}

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Ce script doit etre execute avec les privileges root${NC}"
   exit 1
fi

deps_check
start_operation

#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m'

ENCRYPT=true
VERBOSE=false
INSTALL=false
HELP=false

CurrentDir=$(pwd)

for arg in "$@"; do
  case "$arg" in
    --install | -install | -i | --i | install)
      INSTALL=true
      ;;
    --without-encrypt-pm)
      ENCRYPT=false
      ;;
    --verbose | --debug)
      set -x
      VERBOSE=true
      ;;
    help)
      HELP=true
  esac
done

function deps_check {
    echo "Recherche des dependances"
    if [ "$ENCRYPT" = true ]; then
        if ! command -v "shc" &> /dev/null; then
            echo -e "${RED}Le logiciel SHC n'est pas détecté sur votre systeme, veuillez utilisé l'argument --without-encrypt-pm pour passé ce check${NC}"
	    exit 1
        fi
    fi

    if ! command -v "wget" &> /dev/null; then
        echo -e "${RED}Le logiciel WGET n'est pas détecté sur votre systeme, veuillez l'installé..${NC}"
        exit 1
    fi
}

function install_files {
    wget "https://raw.githubusercontent.com/acth2/CydraProject/main/testing/packagemanagers/software/cydramanager" -P ./pm/ --no-check-certificate -q
    mkdir -p /etc/cydrafetch
    mkdir -p /etc/cydradeps
    mkdir -p /etc/cydraterms 2> /dev/null

    touch /etc/cydrafetch/currentMirror
    mkdir /etc/cydraterms/usersoftware
    mkdir /etc/cydraterms/installedsoftware
    wget "https://raw.githubusercontent.com/acth2/CydraProject/main/packagemanager/changelogs.log" -P /etc/cydraterms --no-check-certificate -q
    wget "https://raw.githubusercontent.com/acth2/CydraProject/main/packagemanager/basicmirror.list" -P /etc/cydrafetch/currentMirror.list --no-check-certificate -q
    wget "https://raw.githubusercontent.com/acth2/CydraProject/main/packagemanager/fetch/mainserver.list" -P /etc/cydraterms/mainserver.list --no-check-certificate -q
    wget "https://github.com/acth2/CydraProject/raw/main/packagemanager/installedsoftware/installedarchive.tar.gz" -P /etc/cydraterms/installedsoftware --no-check-certificate -q
    touch /etc/cydrafetch/1.mirror
    touch /etc/cydrafetch/2.mirror
    touch /etc/cydrafetch/3.mirror
    touch /etc/cydrafetch/4.mirror

    if [ ! -d "/usr/cydramanager" ]; then
       mkdir /usr/cydramanager
       mkdir /usr/cydramanager/currentSoftware
       mkdir /usr/cydramanager/oldSoftware
       mkdir /usr/cydramanager/pkgt
       mkdir /usr/cydramanager/md5
    fi

}

function write_files {
    echo "http://mir.archlinux.fr" > /etc/cydrafetch/currentMirror

   tar xf /etc/cydraterms/installedsoftware/installedarchive.tar.gz -C /etc/cydraterms/installedsoftware
   rm -f /etc/cydraterms/installedsoftware/installedarchive.tar.gz
}

function start_operation {
    if [ "$HELP" = true ]; then
        echo -e "Programme d'installation de cydramanager:"
        echo -e "      help:                 Ouvre cette commande"
        echo -e "      --without-encrypt-pm: Le code du gdp sera disponnible avec cat /usr/bin/cydramanager"
        echo -e "      --install           : Le gdp s'installera "
	echo -e "      --verbose           : l'installeur montrera le code éxécuté en temps réel"
        exit 0
    fi


    if [ "$INSTALL" = true ]; then
        clear
        echo -e "${GREEN} -1: Creations des fichiers principaux${NC}"

        install_files

        echo -e "${GREEN} -2: Configuration des fichiers principaux${NC}"

        write_files

        if [ "$ENCRYPT" = true ]; then
            cp -r "./pm/cydramanager" "/usr/bin/cydramanagerns"   
	    shc -f "/usr/bin/cydramanagerns" -o "/usr/bin/cydramanager"
            rm -f "/usr/bin/cydramanagerns*"
	    echo -e "${GREEN} -3: Protection du gestionnaire de packets)${NC}"
	else
            cp -r "./pm/cydramanager" /usr/bin/cydramanager
            echo -e "${ORANGE} -3: Protection du gestionnaire de packets (PASSE)${NC}"
        fi
        chmod +rwx /usr/bin/cydramanager

        echo -e "${GREEN} --: Gestionnaire de packet installé${NC}"
        rm -rf ./pm/*
        echo -e "${ORANGE}USAGE: sudo cydramanager help${NC}"
+    else
        echo -e "${ORANGE}Pour commencé l'installation veuillez utilisé l'argument --install !${NC}"
    fi
}

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Ce script doit etre execute avec les privileges root${NC}"
   exit 1
fi

deps_check
start_operation

if [ "$VERBOSE" = true ]; then
   set +x
fi

exit 0 

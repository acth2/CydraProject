#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m'

ENCRYPT=true
INSTALL=false
HELP=false

CurrentDir=$(pwd)

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
    #if [ "$ENCRYPT" = true ]; then
    #    if [ "$HELP" = false ]; then
    #        if [ ! -f "/usr/local/bin/shc" ]; then
    #            echo -e "${RED}Le logiciel SHC n est pas installé sur votre systeme !\n${ORANGE}Utilisez l'argument --without-encrypt-pm${NC}"
    #            exit 1
    #        fi
    #     fi
    # fi

    if [ ! -f "/usr/bin/wget" ]; then
        echo -e "${RED}Le logiciel WGET n est pas installer sur votre systeme!\nCe logiciel est obligatoire au bon fonctionnement du gestionnaire de packet, veuillez l installe${NC}"
        exit 1
    fi

    if [ ! -f "/usr/bin/lspci" ]; then
        echo -e "${RED}Le logiciel PCIUTILS n est pas installer sur votre systeme!\nCe logiciel est obligatoire au bon fonctionnement du gestionnaire de packet, veuillez l installe${NC}"
        exit 1
    fi
}

function install_files {
    wget "https://raw.githubusercontent.com/acth2/CydraProject/main/testing/packagemanagers/software/cydramanager" -P ./pm/ --no-check-certificate -q
    mkdir -p /etc/cydrafetch
    mkdir -p /etc/cydradeps
    mkdir -p /etc/cydraterms

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
       mkdir /usr/cydramanager/currentSoftware/bin
       mkdir /usr/cydramanager/oldSoftware/bin
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
            echo -e "${ORANGE} -3: Protection du gestionnaire de packets (EN CONS)${NC}"
            cp -r "./pm/cydramanager" /usr/bin/cydramanager        
	else
            cp -r "./pm/cydramanager" /usr/bin/cydramanager
            echo -e "${ORANGE} -3: Protection du gestionnaire de packets (EN CONS)${NC}"
        fi
        chmod +rwx /usr/bin/cydramanager

        echo -e "${GREEN} --: Gestionnaire de packet installé${NC}"
        rm -rf ./pm/*
        echo -e "${ORANGE}USAGE: sudo cydramanager help${NC}"
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

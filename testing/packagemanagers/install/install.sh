#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
NC='\033[0m'

function start_operation {
    cp -r pm/cydramanager /usr/bin/cydramanager
    echo -e "${GREEN}done.${NC}"
}

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Uh oh, you need to be root to continue!${NC}"
   exit 1
fi

start_operation

exit 0 

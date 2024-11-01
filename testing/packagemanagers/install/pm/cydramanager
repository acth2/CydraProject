#!/bin/bash

# CydraOS Package Managers' Manager Script
# A lot of manager(s) wow

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

function update_managers() {
    echo -e "${CYAN}Updating Homebrew and Nix packages...${NC}"
    brew update && brew upgrade
    nix-channel --update && nix-env -u
    echo -e "${GREEN}Updates complete.${NC}"
}

function is_installed() {
    package=$1
    if brew list --formula | grep -q "^${package}\$"; then
        echo -e "${YELLOW}$package is already installed with Homebrew.${NC}"
        return 0
    elif nix-env -q | grep -q "^${package}-"; then
        echo -e "${YELLOW}$package is already installed with Nix.${NC}"
        return 0
    else
        return 1
    fi
}

function install_package() {
    package=$1
    manager=${2:-"auto"}

    if is_installed "$package"; then
        echo -e "${YELLOW}$package is already installed. Skipping installation.${NC}"
        return
    fi

    if [[ "$manager" == "brew" ]]; then
        echo -e "${CYAN}Attempting to install $package with Homebrew...${NC}"
        brew install "$package" || echo -e "${RED}cydramanager error log: FROM Homebrew${NC}"
    elif [[ "$manager" == "nix" ]]; then
        echo -e "${CYAN}Attempting to install $package with Nix...${NC}"
        nix-env -iA nixpkgs."$package" || echo -e "${RED}cydramanager error log: FROM Nix${NC}"
    else
        echo -e "${CYAN}Searching Homebrew first for $package...${NC}"
        if brew search "^${package}\$" | grep -q "^${package}\$"; then
            brew install "$package" || echo -e "${RED}cydramanager error log: FROM Homebrew${NC}"
        else
            echo -e "${CYAN}$package not found in Homebrew. Trying Nix...${NC}"
            nix-env -iA nixpkgs."$package" || echo -e "${RED}cydramanager error log: FROM Nix${NC}"
        fi
    fi
}

function uninstall_package() {
    package=$1
    manager=${2:-"auto"}
    error_occurred=false

    if [[ "$manager" == "brew" ]]; then
        echo -e "${CYAN}Attempting to uninstall $package with Homebrew...${NC}"
        if ! brew uninstall "$package" >/dev/null 2>&1; then
            error_occurred=true
            echo -e "${RED}cydramanager error log: FROM Homebrew${NC}"
        fi
    elif [[ "$manager" == "nix" ]]; then
        echo -e "${CYAN}Attempting to uninstall $package with Nix...${NC}"
        if ! nix-env -e "$package" >/dev/null 2>&1; then
            error_occurred=true
            echo -e "${RED}cydramanager error log: FROM Nix${NC}"
        fi
    else
        echo -e "${CYAN}Attempting to uninstall $package with Homebrew...${NC}"
        if brew list --formula | grep -q "^${package}\$"; then
            if ! brew uninstall "$package" >/dev/null 2>&1; then
                error_occurred=true
                echo -e "${RED}cydramanager error log: FROM Homebrew${NC}"
            fi
        elif nix-env -q | grep -q "^${package}-"; then
            echo -e "${CYAN}Attempting to uninstall $package with Nix...${NC}"
            if ! nix-env -e "$package" >/dev/null 2>&1; then
                error_occurred=true
                echo -e "${RED}cydramanager error log: FROM Nix${NC}"
            fi
        else
            echo -e "${RED}Error: $package is not installed with either manager.${NC}"
        fi
    fi
}

function cydraos_help() {
    echo -e "${BLUE}CydraOS Package Manager${NC}"
    echo -e "Usage: $0 [command] <options>"
    echo ""
    echo -e "Commands:"
    echo -e "  ${GREEN}update${NC}                        Update both Homebrew and Nix package managers."
    echo -e "  ${GREEN}install <pkg> [manager]${NC}       Install a package. Optionally specify 'brew' or 'nix' to install with that manager."
    echo -e "  ${GREEN}uninstall <pkg> [manager]${NC}     Uninstall a package. Optionally specify 'brew' or 'nix' to uninstall with that manager."
    echo -e "  ${GREEN}help${NC}                          Display this help message."
    echo ""
    echo -e "Examples:"
    echo -e "  $0 update                     # Updates all packages in both managers"
    echo -e "  $0 install curl               # Installs 'curl' preferring Homebrew, then Nix if not found"
    echo -e "  $0 install wget nix           # Installs 'wget' using Nix only"
    echo -e "  $0 uninstall curl             # Uninstalls 'curl' from the installed manager"
    echo ""
    echo -e "More:"
    echo -e "  # Cydramanager will always try to install with Homebrew first"
    echo -e "  # Cydramanager needs to be used with both Homebrew AND Nix"
    echo -e "  # Cydramanager code is completely open; you can modify it!"
}

# Main script
case "$1" in
    update)
        update_managers
        ;;
    install)
        package_name=$2
        manager=${3:-"auto"}
        if [[ -z "$package_name" ]]; then
            echo -e "${RED}Error: Please specify a package name to install.${NC}"
            cydraos_help
            exit 1
        fi
        install_package "$package_name" "$manager"
        ;;
    uninstall)
        package_name=$2
        manager=${3:-"auto"}
        if [[ -z "$package_name" ]]; then
            echo -e "${RED}Error: Please specify a package name to uninstall.${NC}"
            cydraos_help
            exit 1
        fi
        uninstall_package "$package_name" "$manager"
        ;;
    help)
        cydraos_help
        ;;
    *)
        echo -e "${RED}Error: Unknown command '$1'${NC}"
        cydraos_help
        ;;
esac

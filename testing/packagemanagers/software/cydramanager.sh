#!/bin/bash

# CydraOS Package Managers' Manager Script
# A lot of manager(s) wow

function update_managers() {
    echo "Updating Homebrew and Nix packages..."
    brew update && brew upgrade
    nix-channel --update && nix-env -u
    echo "Updates complete."
}

function is_installed() {
    package=$1
    if brew list --formula | grep -q "^${package}\$"; then
        echo "$package is already installed with Homebrew."
        return 0
    elif nix-env -q | grep -q "^${package}-"; then
        echo "$package is already installed with Nix."
        return 0
    else
        return 1
    fi
}

function install_package() {
    package=$1
    manager=${2:-"auto"}

    if is_installed "$package"; then
        echo "$package is already installed. Skipping installation."
        return
    fi

    if [[ "$manager" == "brew" ]]; then
        echo "Attempting to install $package with Homebrew..."
        brew install "$package" || echo "cydramanager error log: FROM Homebrew"
    elif [[ "$manager" == "nix" ]]; then
        echo "Attempting to install $package with Nix..."
        nix-env -iA nixpkgs."$package" || echo "cydramanager error log: FROM Nix"
    else
        echo "Searching Homebrew first for $package..."
        if brew search "^${package}\$" | grep -q "^${package}\$"; then
            brew install "$package" || echo "cydramanager error log: FROM Homebrew"
        else
            echo "$package not found in Homebrew. Trying Nix..."
            nix-env -iA nixpkgs."$package" || echo "cydramanager error log: FROM Nix"
        fi
    fi
}

function uninstall_package() {
    package=$1
    manager=${2:-"auto"}
    error_occurred=false

    if [[ "$manager" == "brew" ]]; then
        echo "Attempting to uninstall $package with Homebrew..."
        if ! brew uninstall "$package" >/dev/null 2>&1; then
            error_occurred=true
            echo "cydramanager error log: FROM Homebrew"
        fi
    elif [[ "$manager" == "nix" ]]; then
        echo "Attempting to uninstall $package with Nix..."
        if ! nix-env -e "$package" >/dev/null 2>&1; then
            error_occurred=true
            echo "cydramanager error log: FROM Nix"
        fi
    else
        echo "Attempting to uninstall $package with Homebrew..."
        if brew list --formula | grep -q "^${package}\$"; then
            if ! brew uninstall "$package" >/dev/null 2>&1; then
                error_occurred=true
                echo "cydramanager error log: FROM Homebrew"
            fi
        elif nix-env -q | grep -q "^${package}-"; then
            echo "Attempting to uninstall $package with Nix..."
            if ! nix-env -e "$package" >/dev/null 2>&1; then
                error_occurred=true
                echo "cydramanager error log: FROM Nix"
            fi
        else
            echo "Error: $package is not installed with either manager."
        fi
    fi
}

function cydraos_help() {
    echo "CydraOS Package Manager Manager"
    echo "Usage: $0 [command] <options>"
    echo ""
    echo "Commands:"
    echo "  update                        Update both Homebrew and Nix package managers."
    echo "  install <pkg> [manager]       Install a package. Optionally specify 'brew' or 'nix' to install with that manager."
    echo "  uninstall <pkg> [manager]     Uninstall a package. Optionally specify 'brew' or 'nix' to uninstall with that manager."
    echo "  help                          Display this help message."
    echo ""
    echo "Examples:"
    echo "  $0 update                     # Updates all packages in both managers"
    echo "  $0 install curl               # Installs 'curl' preferring Homebrew, then Nix if not found"
    echo "  $0 install wget nix           # Installs 'wget' using Nix only"
    echo "  $0 uninstall curl             # Uninstalls 'curl' from the installed manager"
}

case "$1" in
    update)
        update_managers
        ;;
    install)
        package_name=$2
        manager=${3:-"auto"}
        if [[ -z "$package_name" ]]; then
            echo "Error: Please specify a package name to install."
            cydraos_help
            exit 1
        fi
        install_package "$package_name" "$manager"
        ;;
    uninstall)
        package_name=$2
        manager=${3:-"auto"}
        if [[ -z "$package_name" ]]; then
            echo "Error: Please specify a package name to uninstall."
            cydraos_help
            exit 1
        fi
        uninstall_package "$package_name" "$manager"
        ;;
    help)
        cydraos_help
        ;;
    *)
        echo "Error: Unknown command '$1'"
        cydraos_help
        ;;
esac

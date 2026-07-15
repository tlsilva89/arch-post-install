#!/bin/bash

set -e

# Script para desinstalar pacotes instalados pelo arch-post-install

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

print_warning() {
    echo -e "${RED}⚠ $1${NC}"
}

run_sudo() {
    if [[ $EUID -ne 0 ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Verifica privilégios
if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
    print_error "Este script requer privilégios de root ou acesso a sudo"
    exit 1
fi

print_header "ARCH POST-INSTALL - DESINSTALAÇÃO"
echo ""
print_warning "Esta ação removerá pacotes instalados. Tenha cuidado!"
echo ""

# Pacotes para desinstalar
PACMAN_PACKAGES=(
    "git"
    "base-devel"
    "ark"
    "unrar"
    "kitty"
    "fish"
    "nodejs"
    "npm"
    "jdk-openjdk"
    "dotnet-sdk"
    "dotnet-runtime"
    "python"
    "telegram-desktop"
    "qbittorrent"
    "discord"
    "steam"
    "thunderbird"
    "okular"
    "kate"
    "gwenview"
    "kcalc"
    "spotify-launcher"
    "efibootmgr"
    "podman-desktop"
    "docker"
    "docker-compose"
    "dbeaver"
)

FLATPAK_APPS=(
    "org.videolan.VLC"
    "com.termius.Termius"
    "com.heroicgameslauncher.hgl"
)

AUR_PACKAGES=(
    "brave-bin"
    "onlyoffice-bin"
    "visual-studio-code-bin"
)

echo "Pacotes do Pacman: ${#PACMAN_PACKAGES[@]}"
echo "Apps Flatpak: ${#FLATPAK_APPS[@]}"
echo "Pacotes AUR: ${#AUR_PACKAGES[@]}"
echo ""

read -p "Deseja continuar com a desinstalação? Digite 'sim' para confirmar: " confirmation

if [[ "$confirmation" != "sim" ]]; then
    print_info "Desinstalação cancelada"
    exit 0
fi

echo ""

# Remove pacotes do AUR
if command -v paru &> /dev/null; then
    if [[ ${#AUR_PACKAGES[@]} -gt 0 ]]; then
        print_header "Removendo pacotes do AUR"
        for package in "${AUR_PACKAGES[@]}"; do
            print_info "Removendo $package..."
            paru -R "$package" --noconfirm || print_error "Falha ao remover $package"
        done
        print_success "Pacotes do AUR removidos"
    fi
fi

echo ""

# Remove apps Flatpak
if command -v flatpak &> /dev/null; then
    if [[ ${#FLATPAK_APPS[@]} -gt 0 ]]; then
        print_header "Removendo aplicações Flatpak"
        for app in "${FLATPAK_APPS[@]}"; do
            print_info "Removendo $app..."
            run_sudo flatpak remove -y "$app" || print_error "Falha ao remover $app"
        done
        print_success "Aplicações Flatpak removidas"
    fi
fi

echo ""

# Remove pacotes do Pacman
print_header "Removendo pacotes do Pacman"

# Filtra apenas pacotes instalados
local_packages=()
for package in "${PACMAN_PACKAGES[@]}"; do
    if pacman -Q "$package" &> /dev/null; then
        local_packages+=("$package")
    fi
done

if [[ ${#local_packages[@]} -gt 0 ]]; then
    run_sudo pacman -R "${local_packages[@]}" --noconfirm
    print_success "${#local_packages[@]} pacotes do Pacman removidos"
else
    print_info "Nenhum pacote do Pacman instalado para remover"
fi

echo ""

# Oferece remover dependências órfãs
print_header "Limpeza"
print_info "Removendo dependências não utilizadas..."
run_sudo pacman -Qdtq | run_sudo pacman -Rs - --noconfirm || true

print_success "Limpeza concluída"

echo ""
print_header "DESINSTALAÇÃO CONCLUÍDA"
echo "Todos os pacotes foram removidos"

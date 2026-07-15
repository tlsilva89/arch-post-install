#!/bin/bash

set -e

# Script de instalação que lê a configuração de packages.conf
# Uso: ./install-from-config.sh [config-file]

CONFIG_FILE="${1:-./packages.conf}"
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

# Verifica se arquivo de configuração existe
if [[ ! -f "$CONFIG_FILE" ]]; then
    print_error "Arquivo de configuração não encontrado: $CONFIG_FILE"
    exit 1
fi

# Função para executar comandos com sudo
run_sudo() {
    if [[ $EUID -ne 0 ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Parse do arquivo de configuração
parse_config() {
    local section="$1"
    grep -E "^[a-zA-Z0-9._-]" "$CONFIG_FILE" | grep -v "^#" | grep -v "^$"
}

# Separa pacotes por tipo
declare -a PACMAN_PACKAGES
declare -a FLATPAK_APPS
declare -a AUR_PACKAGES
declare -a NPM_PACKAGES

# Seção atual: pacman | flatpak | aur | npm
section="pacman"

while IFS= read -r line; do
    # Detecta seções pelos cabeçalhos (linhas de comentário) ANTES de pular comentários
    if [[ "$line" =~ FLATPAK ]]; then
        section="flatpak"
        continue
    elif [[ "$line" =~ AUR ]]; then
        section="aur"
        continue
    elif [[ "$line" =~ NPM ]]; then
        section="npm"
        continue
    fi

    # Pula comentários e linhas vazias
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue

    # Remove comentários inline e espaços nas pontas
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    [[ -z "$line" ]] && continue

    # Classifica o pacote pela seção atual
    case "$section" in
        flatpak) FLATPAK_APPS+=("$line") ;;
        aur)     AUR_PACKAGES+=("$line") ;;
        npm)     NPM_PACKAGES+=("$line") ;;
        *)       PACMAN_PACKAGES+=("$line") ;;
    esac
done < "$CONFIG_FILE"

# Atualiza sistema
update_system() {
    print_header "Atualizando sistema"
    run_sudo pacman -Syu --noconfirm
    print_success "Sistema atualizado"
}

# Instala pacotes do pacman
install_pacman() {
    if [[ ${#PACMAN_PACKAGES[@]} -eq 0 ]]; then
        print_info "Nenhum pacote do Pacman para instalar"
        return
    fi

    print_header "Instalando ${#PACMAN_PACKAGES[@]} pacotes do Pacman"

    for package in "${PACMAN_PACKAGES[@]}"; do
        print_info "Instalando $package..."
        run_sudo pacman -S "$package" --noconfirm --needed || print_error "Falha ao instalar $package"
    done

    print_success "Pacotes do Pacman instalados"
}

# Configura Flatpak
setup_flatpak() {
    if [[ ${#FLATPAK_APPS[@]} -eq 0 ]]; then
        print_info "Nenhuma aplicação Flatpak para instalar"
        return
    fi

    print_header "Configurando Flatpak"

    if ! pacman -Q flatpak &> /dev/null; then
        run_sudo pacman -S flatpak --noconfirm
    fi

    print_info "Adicionando repositório Flathub..."
    run_sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

    print_info "Instalando ${#FLATPAK_APPS[@]} aplicações Flatpak..."
    for app in "${FLATPAK_APPS[@]}"; do
        print_info "Instalando $app..."
        run_sudo flatpak install -y flathub "$app" || print_error "Falha ao instalar $app"
    done

    print_success "Flatpak configurado e aplicações instaladas"
}

# Instala Paru
install_paru() {
    if [[ ${#AUR_PACKAGES[@]} -eq 0 ]]; then
        print_info "Nenhum pacote AUR para instalar"
        return
    fi

    if command -v paru &> /dev/null; then
        print_success "Paru já está instalado"
        return
    fi

    print_header "Instalando Paru"

    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm

    cd - > /dev/null
    rm -rf "$temp_dir"

    print_success "Paru instalado"
}

# Instala pacotes AUR
install_aur() {
    if [[ ${#AUR_PACKAGES[@]} -eq 0 ]]; then
        print_info "Nenhum pacote AUR para instalar"
        return
    fi

    if ! command -v paru &> /dev/null; then
        print_error "Paru não está instalado. Abortando instalação de pacotes AUR."
        return 1
    fi

    print_header "Instalando ${#AUR_PACKAGES[@]} pacotes do AUR"

    for package in "${AUR_PACKAGES[@]}"; do
        print_info "Instalando $package..."
        paru -S "$package" --noconfirm || print_error "Falha ao instalar $package"
    done

    print_success "Pacotes do AUR instalados"
}

# Instala pacotes globais do npm
install_npm() {
    if [[ ${#NPM_PACKAGES[@]} -eq 0 ]]; then
        print_info "Nenhum pacote npm para instalar"
        return
    fi

    if ! command -v npm &> /dev/null; then
        print_error "npm não está instalado. Abortando instalação de pacotes npm."
        return 1
    fi

    print_header "Instalando ${#NPM_PACKAGES[@]} pacotes globais do npm"

    for package in "${NPM_PACKAGES[@]}"; do
        print_info "Instalando $package..."
        run_sudo npm install -g "$package" || print_error "Falha ao instalar $package"
    done

    print_success "Pacotes globais do npm instalados"
}

# Configurações pós-instalação
post_install() {
    print_header "Configurações pós-instalação"

    # Docker
    if pacman -Q docker &> /dev/null; then
        print_info "Habilitando Docker..."
        run_sudo systemctl enable docker
        run_sudo systemctl start docker || true

        if [[ $EUID -ne 0 ]]; then
            print_info "Adicionando usuário ao grupo docker..."
            run_sudo usermod -aG docker $USER
        fi
    fi

    print_success "Configurações pós-instalação concluídas"
}

# Main
main() {
    print_header "ARCH POST-INSTALL (Config)"
    echo "Usando configuração: $CONFIG_FILE"
    echo "Pacotes Pacman: ${#PACMAN_PACKAGES[@]}"
    echo "Apps Flatpak: ${#FLATPAK_APPS[@]}"
    echo "Pacotes AUR: ${#AUR_PACKAGES[@]}"
    echo "Pacotes npm: ${#NPM_PACKAGES[@]}"
    echo ""

    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        print_error "Este script requer privilégios de root ou acesso a sudo"
        exit 1
    fi

    read -p "Continuar com a instalação? (s/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        print_info "Instalação cancelada"
        exit 0
    fi

    update_system
    echo ""
    install_pacman
    echo ""
    setup_flatpak
    echo ""
    install_paru
    echo ""
    install_aur
    echo ""
    install_npm
    echo ""
    post_install
    echo ""

    print_header "INSTALAÇÃO CONCLUÍDA"
}

main "$@"

#!/bin/bash

set -e

# Diretório onde este script está (para localizar kitty.conf etc.)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
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

# Verifica se é root ou tem acesso a sudo
check_privileges() {
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        print_error "Este script requer privilégios de root ou acesso a sudo sem senha"
        exit 1
    fi
}

# Função para executar comandos com sudo
run_sudo() {
    if [[ $EUID -ne 0 ]]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Usuário e home reais (mesmo quando o script roda via sudo)
if [[ -n "$SUDO_USER" ]]; then
    TARGET_USER="$SUDO_USER"
else
    TARGET_USER="$USER"
fi
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

# Executa um comando como o usuário alvo (nunca como root)
run_as_user() {
    if [[ "$(id -un)" == "$TARGET_USER" ]]; then
        "$@"
    else
        run_sudo -u "$TARGET_USER" "$@"
    fi
}

# Atualiza o sistema
update_system() {
    print_header "Atualizando sistema"
    run_sudo pacman -Syu --noconfirm
    print_success "Sistema atualizado"
}

# Habilita o repositório multilib (necessário p/ Steam e libs 32-bit)
enable_multilib() {
    print_header "Habilitando repositório multilib"

    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        print_success "multilib já está habilitado"
        return
    fi

    print_info "Descomentando [multilib] em /etc/pacman.conf..."
    run_sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
    run_sudo pacman -Sy
    print_success "multilib habilitado"
}

# Detecta e instala microcode da CPU + drivers de vídeo corretos
install_hardware_drivers() {
    print_header "Detectando hardware e instalando drivers"

    # --- Microcode da CPU ---
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        print_info "CPU Intel detectada → intel-ucode"
        run_sudo pacman -S intel-ucode --noconfirm --needed || print_error "Falha ao instalar intel-ucode"
    elif grep -q "AuthenticAMD" /proc/cpuinfo; then
        print_info "CPU AMD detectada → amd-ucode"
        run_sudo pacman -S amd-ucode --noconfirm --needed || print_error "Falha ao instalar amd-ucode"
    fi

    # --- Drivers de vídeo (com libs 32-bit para Steam) ---
    local gpu_info
    gpu_info="$(lspci 2>/dev/null | grep -iE 'vga|3d|display')"

    if echo "$gpu_info" | grep -iq "intel"; then
        print_info "GPU Intel detectada → mesa + vulkan-intel"
        run_sudo pacman -S mesa lib32-mesa vulkan-intel lib32-vulkan-intel \
            intel-media-driver --noconfirm --needed || print_error "Falha nos drivers Intel"
    fi

    if echo "$gpu_info" | grep -iqE "amd|radeon|ati"; then
        print_info "GPU AMD detectada → mesa + vulkan-radeon"
        run_sudo pacman -S mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon \
            libva-mesa-driver lib32-libva-mesa-driver --noconfirm --needed || print_error "Falha nos drivers AMD"
    fi

    if echo "$gpu_info" | grep -iq "nvidia"; then
        print_info "GPU NVIDIA detectada → nvidia-open + suporte 32-bit"
        run_sudo pacman -S nvidia-open nvidia-utils lib32-nvidia-utils \
            --noconfirm --needed || print_error "Falha nos drivers NVIDIA"
    fi

    print_success "Drivers de hardware instalados"
}

# Instala pacotes do repositório oficial
install_pacman_packages() {
    print_header "Instalando pacotes do Pacman"

    local packages=(
        "git"
        "base-devel"
        "ark"
        "unrar"
        "kitty"
        "fish"
        "nerd-fonts"
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

        # --- Essenciais do sistema (não vêm no archinstall mínimo) ---
        "sof-firmware"              # firmware de áudio (notebooks modernos)
        "power-profiles-daemon"     # gerenciamento de energia (KDE PowerDevil)
        "networkmanager"            # gerência de rede/Wi-Fi
        "bluez"                     # stack Bluetooth
        "bluez-utils"
        "xdg-desktop-portal-kde"    # integração de apps Flatpak no KDE
        "p7zip"                     # backend do Ark (.7z)
        "unzip"                     # backend do Ark (.zip)
        "zip"
        "firewalld"                 # firewall
        "reflector"                 # atualiza mirrors mais rápidos
        "pacman-contrib"            # paccache, checkupdates, etc.
        "openssh"                   # cliente/servidor SSH
        "man-db"                    # páginas de manual
        "man-pages"
        "wget"

        # --- Impressão ---
        "cups"
        "cups-pdf"
        "print-manager"
        "system-config-printer"

        # --- Fontes (renderização web/Discord) ---
        "noto-fonts-cjk"            # caracteres asiáticos
        "noto-fonts-emoji"          # emojis coloridos
        "ttf-liberation"            # substitutos de Arial/Times
        "ttf-dejavu"
    )

    for package in "${packages[@]}"; do
        print_info "Instalando $package..."
        run_sudo pacman -S "$package" --noconfirm --needed || print_error "Falha ao instalar $package"
    done

    print_success "Pacotes do Pacman instalados"
}

# Instala e configura Flatpak
install_flatpak() {
    print_header "Configurando Flatpak"

    # Instala flatpak se não estiver instalado
    if ! pacman -Q flatpak &> /dev/null; then
        run_sudo pacman -S flatpak --noconfirm
    fi

    # Adiciona repositório Flathub
    print_info "Adicionando repositório Flathub..."
    run_sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

    print_success "Flatpak configurado"
}

# Instala aplicações Flatpak
install_flatpak_apps() {
    print_header "Instalando aplicações Flatpak"

    local flatpak_apps=(
        "org.videolan.VLC"
        "com.termius.Termius"
        "com.heroicgameslauncher.hgl"
    )

    for app in "${flatpak_apps[@]}"; do
        print_info "Instalando $app..."
        run_sudo flatpak install -y flathub "$app" || print_error "Falha ao instalar $app"
    done

    print_success "Aplicações Flatpak instaladas"
}

# Instala Paru (AUR helper)
install_paru() {
    print_header "Instalando Paru (AUR helper)"

    if command -v paru &> /dev/null; then
        print_success "Paru já está instalado"
        return
    fi

    print_info "Clonando repositório Paru..."
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm

    cd - > /dev/null
    rm -rf "$temp_dir"

    print_success "Paru instalado"
}

# Instala pacotes do AUR
install_aur_packages() {
    print_header "Instalando pacotes do AUR"

    if ! command -v paru &> /dev/null; then
        print_error "Paru não está instalado. Abortando instalação de pacotes AUR."
        return 1
    fi

    local aur_packages=(
        "brave-bin"
        "onlyoffice-bin"
        "visual-studio-code-bin"
    )

    for package in "${aur_packages[@]}"; do
        print_info "Instalando $package..."
        paru -S "$package" --noconfirm || print_error "Falha ao instalar $package"
    done

    print_success "Pacotes do AUR instalados"
}

# Instala pacotes globais do npm
install_npm_packages() {
    print_header "Instalando pacotes globais do npm"

    if ! command -v npm &> /dev/null; then
        print_error "npm não está instalado. Abortando instalação de pacotes npm."
        return 1
    fi

    local npm_packages=(
        "@angular/cli"
    )

    for package in "${npm_packages[@]}"; do
        print_info "Instalando $package..."
        run_sudo npm install -g "$package" || print_error "Falha ao instalar $package"
    done

    print_success "Pacotes globais do npm instalados"
}

# Configura Kitty, Fish, Oh My Fish e tema agnoster
configure_terminal_shell() {
    print_header "Configurando terminal (Kitty) e shell (Fish)"

    local fish_path
    fish_path="$(command -v fish || echo /usr/bin/fish)"

    # --- 1. Aplica o kitty.conf ---
    if [[ -f "$SCRIPT_DIR/kitty.conf" ]]; then
        print_info "Aplicando kitty.conf em ~/.config/kitty/..."
        run_as_user mkdir -p "$TARGET_HOME/.config/kitty"
        run_as_user cp "$SCRIPT_DIR/kitty.conf" "$TARGET_HOME/.config/kitty/kitty.conf"
        print_success "kitty.conf aplicado"
    else
        print_error "kitty.conf não encontrado em $SCRIPT_DIR — pulando"
    fi

    # --- 2. Define Fish como shell padrão ---
    if grep -q "^$fish_path$" /etc/shells 2>/dev/null || run_sudo grep -q "^$fish_path$" /etc/shells; then
        :
    else
        print_info "Registrando $fish_path em /etc/shells..."
        echo "$fish_path" | run_sudo tee -a /etc/shells > /dev/null
    fi
    print_info "Definindo Fish como shell padrão de $TARGET_USER..."
    run_sudo chsh -s "$fish_path" "$TARGET_USER" || print_error "Falha ao alterar o shell padrão"

    # --- 3. Define Kitty como terminal padrão ---
    print_info "Definindo Kitty como terminal padrão..."
    # KDE Plasma (kwriteconfig6 / kwriteconfig5)
    if command -v kwriteconfig6 &> /dev/null; then
        run_as_user kwriteconfig6 --file kdeglobals --group General --key TerminalApplication kitty || true
    elif command -v kwriteconfig5 &> /dev/null; then
        run_as_user kwriteconfig5 --file kdeglobals --group General --key TerminalApplication kitty || true
    fi
    # Fallback genérico: variável TERMINAL para o fish
    run_as_user mkdir -p "$TARGET_HOME/.config/fish"
    if ! run_as_user grep -q "set -gx TERMINAL kitty" "$TARGET_HOME/.config/fish/config.fish" 2>/dev/null; then
        echo "set -gx TERMINAL kitty" | run_as_user tee -a "$TARGET_HOME/.config/fish/config.fish" > /dev/null
    fi

    # --- 4. Instala Oh My Fish + tema agnoster ---
    if run_as_user test -d "$TARGET_HOME/.local/share/omf"; then
        print_success "Oh My Fish já está instalado"
    else
        print_info "Instalando Oh My Fish..."
        local omf_installer="/tmp/omf-install-$$"
        if curl -fsSL https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install -o "$omf_installer"; then
            chmod +r "$omf_installer"
            run_as_user fish "$omf_installer" --noninteractive --yes || print_error "Falha ao instalar Oh My Fish"
            rm -f "$omf_installer"
        else
            print_error "Não foi possível baixar o instalador do Oh My Fish"
        fi
    fi

    print_info "Instalando e ativando o tema agnoster..."
    run_as_user fish -c "omf install agnoster; omf theme agnoster" || print_error "Falha ao configurar o tema agnoster"

    print_success "Terminal e shell configurados"
}

# Configurações pós-instalação
post_install_config() {
    print_header "Configurações pós-instalação"

    # Habilita serviços do sistema (apenas se o pacote estiver instalado)
    enable_service_if_installed() {
        local pkg="$1" svc="$2"
        if pacman -Q "$pkg" &> /dev/null; then
            print_info "Habilitando $svc..."
            run_sudo systemctl enable "$svc" || print_error "Falha ao habilitar $svc"
        fi
    }

    enable_service_if_installed docker docker.service
    enable_service_if_installed networkmanager NetworkManager.service
    enable_service_if_installed bluez bluetooth.service
    enable_service_if_installed cups cups.service
    enable_service_if_installed firewalld firewalld.service
    enable_service_if_installed power-profiles-daemon power-profiles-daemon.service

    # Inicia o Docker imediatamente (os demais sobem no próximo boot)
    if pacman -Q docker &> /dev/null; then
        run_sudo systemctl start docker || true
    fi

    # Adiciona o usuário ao grupo docker
    print_info "Adicionando $TARGET_USER ao grupo docker..."
    run_sudo usermod -aG docker "$TARGET_USER"
    print_info "Necessário logout/login para as mudanças de grupo terem efeito"

    print_success "Configurações pós-instalação concluídas"
}

# Função principal
main() {
    print_header "SCRIPT DE PÓS-INSTALAÇÃO ARCH LINUX"
    echo ""

    check_privileges

    update_system
    echo ""

    enable_multilib
    echo ""

    install_hardware_drivers
    echo ""

    install_pacman_packages
    echo ""

    install_flatpak
    echo ""

    install_flatpak_apps
    echo ""

    install_paru
    echo ""

    install_aur_packages
    echo ""

    install_npm_packages
    echo ""

    configure_terminal_shell
    echo ""

    post_install_config
    echo ""

    print_header "INSTALAÇÃO CONCLUÍDA"
    echo -e "${GREEN}Todos os pacotes foram instalados com sucesso!${NC}"
    echo ""
    echo "Já configurado automaticamente:"
    echo "  • Fish definido como shell padrão"
    echo "  • Kitty definido como terminal padrão (+ kitty.conf aplicado)"
    echo "  • Oh My Fish instalado com o tema agnoster"
    echo ""
    echo "Próximos passos recomendados:"
    echo "1. Faça logout e login novamente para aplicar o shell padrão e os grupos"
    echo "2. Abra o Kitty para ver o tema agnoster + Dracula Purple"
}

main "$@"

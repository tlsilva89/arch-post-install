# Script de Pós-Instalação Arch Linux

Script automatizado para configurar um sistema **Arch Linux + KDE Plasma** (instalado via `archinstall`) pronto para uso, com foco em **desenvolvimento web**. Instala pacotes, drivers, configura terminal/shell e habilita serviços essenciais.

## 📋 O que o script instala

### Pacotes do Repositório Oficial (Pacman)
- **Desenvolvimento**: git, base-devel, nodejs, npm, python, jdk-openjdk (Java), dotnet-sdk + dotnet-runtime (.NET)
- **Terminal & Shell**: kitty, fish
- **Fontes**: `nerd-fonts` (grupo completo — ~69 fontes), noto-fonts-emoji, noto-fonts-cjk, ttf-liberation, ttf-dejavu
- **Compressão**: ark, unrar, p7zip, unzip, zip
- **Comunicação**: telegram-desktop, discord, thunderbird
- **Multimídia**: qbittorrent, spotify-launcher
- **Gaming**: steam
- **Aplicações KDE**: okular, kate, gwenview, kcalc
- **Container**: podman-desktop, docker, docker-compose
- **Banco de Dados**: dbeaver
- **Sistema/Boot**: efibootmgr
- **Essenciais**: sof-firmware, power-profiles-daemon, networkmanager, bluez, bluez-utils, xdg-desktop-portal-kde, firewalld, reflector, pacman-contrib, openssh, man-db, man-pages, wget
- **Impressão**: cups, cups-pdf, print-manager, system-config-printer

### Drivers detectados automaticamente
O script detecta seu hardware e instala os drivers corretos:
- **Microcode da CPU**: `intel-ucode` ou `amd-ucode`
- **GPU**: mesa + Vulkan adequado (Intel / AMD / NVIDIA) com libs 32-bit para Steam/Proton

### Pacotes globais do npm
- Angular CLI (`@angular/cli`)

### Aplicações Flatpak
- VLC
- Termius
- Heroic Games Launcher (Epic Games / GOG / Amazon Prime)

### Pacotes AUR (via Paru)
- Brave Browser (`brave-bin`)
- OnlyOffice Desktop
- Visual Studio Code

## ⚙️ Configuração automática do terminal

Além de instalar pacotes, o script deixa o ambiente pronto:
- ✅ **Fish** definido como shell padrão
- ✅ **Kitty** definido como terminal padrão + `kitty.conf` aplicado (tema Dracula Purple)
- ✅ **Oh My Fish** instalado com o tema **agnoster**

## 🔌 Serviços habilitados automaticamente

O script habilita (e inicia, quando aplicável) os serviços — apenas se o pacote correspondente estiver instalado:
- `docker`
- `NetworkManager`
- `bluetooth`
- `cups` (impressão)
- `firewalld`
- `power-profiles-daemon`

## 🚀 Como usar

### 1. Prepare o repositório
```bash
git clone https://github.com/seu-usuario/arch-post-install.git
cd arch-post-install
```

### 2. Execute o script (como usuário normal)
```bash
./install.sh
```

> 💡 Rode como **seu usuário** (não como root). O script usa `sudo` internamente quando precisa, e detecta o usuário real via `$SUDO_USER` caso rode com sudo — assim as configurações de shell/terminal vão para o seu perfil, e não para o root.

### 3. Ao final
Faça **logout e login** para aplicar o shell padrão (Fish) e as permissões de grupo (Docker).

## 🔀 Modo alternativo: instalação customizável

Em vez do `install.sh`, você pode escolher exatamente o que instalar editando um arquivo de configuração:

```bash
nano packages.conf          # comente/descomente os pacotes desejados
./install-from-config.sh
```

O `packages.conf` separa os pacotes em seções: **Pacman**, **Flatpak**, **AUR** e **NPM**.

> ⚠️ O modo config instala **apenas os pacotes** listados. A auto-detecção de drivers, o `multilib`, a configuração de terminal e a habilitação de serviços existem **somente no `install.sh`**.

## 🗑️ Desinstalação

```bash
./uninstall.sh
```

Você precisará confirmar digitando `sim`. Remove os pacotes Pacman/Flatpak/AUR principais e limpa dependências órfãs.

> ℹ️ A desinstalação **não** reverte as configurações de shell/terminal nem remove drivers/microcode ou os pacotes essenciais do sistema.

## ⚙️ Requisitos

- Arch Linux + KDE Plasma recém-instalado (via `archinstall`)
- Acesso a `sudo`
- Conexão com a internet

## 📝 Ordem de execução do script

1. ✅ Atualiza o sistema (`pacman -Syu`)
2. ✅ Habilita o repositório **multilib** (necessário p/ Steam)
3. ✅ Detecta hardware e instala **microcode + drivers de vídeo**
4. ✅ Instala pacotes do repositório oficial
5. ✅ Configura Flatpak (Flathub) e instala aplicações Flatpak
6. ✅ Instala Paru (AUR helper) e pacotes do AUR
7. ✅ Instala pacotes globais do npm (Angular CLI)
8. ✅ Configura Kitty + Fish + Oh My Fish (tema agnoster)
9. ✅ Habilita serviços e adiciona o usuário ao grupo `docker`

## 🐛 Solução de Problemas

### "Falha ao instalar [pacote]"
- Verifique se o pacote existe: `pacman -Ss nome` (oficial) ou `paru -Ss nome` (AUR)
- Tente instalar manualmente: `sudo pacman -S nome`

### Paru não encontrado
O script tenta instalar automaticamente. Se falhar, instale manualmente:
```bash
git clone https://aur.archlinux.org/paru.git
cd paru && makepkg -si
```

### Tema agnoster com símbolos quebrados
O agnoster precisa de uma Nerd Font. O `kitty.conf` já usa `JetBrainsMono Nerd Font` (incluída no grupo `nerd-fonts`). Se ainda aparecer quebrado, confirme que a fonte foi instalada: `fc-list | grep -i jetbrains`.

### GPU NVIDIA antiga
O script instala `nvidia-open` (padrão para GPUs Turing/RTX 20 em diante). Para placas mais antigas, troque para `nvidia` na função `install_hardware_drivers` do `install.sh`.

## 📦 Customizando o Script

Edite os arrays no `install.sh`:
- `packages` — pacotes do Pacman
- `flatpak_apps` — aplicações Flatpak
- `aur_packages` — pacotes do AUR
- `npm_packages` — pacotes globais do npm

Ou use o `packages.conf` com o `install-from-config.sh`.

## 📂 Estrutura dos Arquivos

```
arch-post-install/
├── install.sh                 # Script principal (completo)
├── install-from-config.sh     # Instalação customizável via packages.conf
├── packages.conf              # Lista de pacotes configurável
├── uninstall.sh               # Desinstalação
├── kitty.conf                 # Configuração do terminal Kitty (Dracula Purple)
├── README.md                  # Este arquivo
└── QUICKSTART.md              # Guia rápido
```

## 💡 Dicas

- Rode em um terminal multiplexado (tmux/screen) para não perder progresso
- Mantenha a conexão estável — alguns pacotes são grandes
- Após instalar, faça logout/login para aplicar shell e grupos
- Configure o Git: `git config --global user.name "Seu Nome"`

## 📄 Licença

Sinta-se livre para usar e modificar este script conforme necessário.

---

**Criado para simplificar a configuração inicial do Arch Linux + KDE Plasma**

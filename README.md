# Script de Pós-Instalação Arch Linux

Script automatizado para instalar e configurar pacotes essenciais após uma instalação limpa do Arch Linux.

## 📋 O que o script instala

### Pacotes do Repositório Oficial (Pacman)
- **Desenvolvimento**: git, base-devel
- **Terminal**: kitty, fish
- **Compressão**: ark, unrar
- **Fontes**: nerd-fonts (múltiplas variações)
- **Runtime**: nodejs, npm, java, .net 10, python
- **Navegador**: brave-browser
- **Comunicação**: telegram-desktop, discord, thunderbird
- **Multimídia**: qbittorrent
- **Gaming**: steam
- **Sistema**: efibootmgr
- **Aplicações**: okular, kate, gwenview, kcalc, spotify-launcher
- **Container**: podman-desktop, docker, docker-compose
- **Banco de Dados**: dbeaver

### Aplicações Flatpak
- VLC
- Termius

### Pacotes AUR (via Paru)
- OnlyOffice Desktop
- Visual Studio Code

## 🚀 Como usar

### 1. Clone ou prepare o repositório
```bash
git clone https://github.com/seu-usuario/arch-post-install.git
cd arch-post-install
```

### 2. Execute o script
```bash
./install.sh
```

Ou com permissões explícitas:
```bash
sudo ./install.sh
```

### 3. Siga as instruções na tela

O script pedirá confirmação para instalar pacotes e processará tudo automaticamente.

## ⚙️ Requisitos

- Arch Linux recém-instalado
- Acesso a sudo ou ser root
- Conexão com a internet
- Repositórios do Arch habilitados

## 📝 O que o script faz

1. ✅ Atualiza o sistema (`pacman -Syu`)
2. ✅ Instala pacotes do repositório oficial
3. ✅ Configura Flatpak e adiciona repositório Flathub
4. ✅ Instala aplicações Flatpak
5. ✅ Instala Paru (AUR helper)
6. ✅ Instala pacotes do AUR
7. ✅ Habilita e inicia Docker
8. ✅ Configura permissões do usuário para Docker

## 🔧 Configurações Pós-Instalação Recomendadas

Após executar o script, execute:

### Trocar shell padrão para Fish
```bash
chsh -s /bin/fish
```

Você precisará fazer logout e login novamente.

### Adicionar seu usuário ao grupo Docker
```bash
sudo usermod -aG docker $USER
```

Faça logout e login para que tenha efeito.

## 🐛 Solução de Problemas

### "Falha ao instalar [pacote]"
- Verifique se o pacote existe no Arch: `pacman -Ss nome-do-pacote`
- Alguns pacotes podem estar em repositórios que não estão habilitados
- Tente instalar manualmente: `sudo pacman -S nome-do-pacote`

### Erro de privilégios
- Execute com `sudo`: `sudo ./install.sh`
- Ou configure sudo sem senha para o seu usuário

### Paru não encontrado
- O script tenta instalar automaticamente
- Se falhar, você pode instalá-lo manualmente:
  ```bash
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si
  ```

## 📦 Customizando o Script

Edite `install.sh` e modifique os arrays de pacotes conforme necessário:

- `packages` - pacotes do Pacman
- `flatpak_apps` - aplicações Flatpak
- `aur_packages` - pacotes do AUR

## 📄 Licença

Sinta-se livre para usar e modificar este script conforme necessário.

## 💡 Dicas

- Execute o script em um terminal multiplexado (tmux/screen) para evitar perda de progresso
- Mantenha a conexão com a internet estável durante a instalação
- Alguns pacotes são grandes e podem levar tempo para baixar
- O Docker requer que você faça logout/login para aplicar permissões de grupo

---

**Criado para simplificar a configuração inicial do Arch Linux**

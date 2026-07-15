# 🚀 Quick Start - Arch Post-Install

Guia rápido para usar o script de pós-instalação do Arch Linux.

## Opção 1️⃣: Instalação Padrão (Recomendado)

```bash
./install.sh
```

Instala todos os pacotes pré-configurados listados no script.

**Tempo estimado**: 30-60 minutos (depende de sua conexão)

## Opção 2️⃣: Instalação Customizável

### Passo 1: Edite os pacotes desejados
```bash
nano packages.conf
# ou
vim packages.conf
```

Descomente os pacotes que deseja instalar e comente o resto.

### Passo 2: Execute o script customizado
```bash
./install-from-config.sh
```

Ou use um arquivo de configuração diferente:
```bash
./install-from-config.sh seu-arquivo.conf
```

## Opção 3️⃣: Desinstalação

Se precisar remover os pacotes instalados:

```bash
./uninstall.sh
```

> ⚠️ Você será pedido para confirmar com a palavra "sim"

## 📋 Checklist Pós-Instalação

> ✅ O `install.sh` já configura **automaticamente**: shell padrão (Fish), terminal padrão (Kitty + kitty.conf), Oh My Fish com tema agnoster, grupo Docker e serviços do sistema.

### 1. Faça logout e login
Necessário para aplicar o **shell padrão (Fish)** e as **permissões de grupo (Docker)**.

### 2. Teste a instalação
```bash
git --version
node --version
ng version          # Angular CLI
docker --version
flatpak --version
paru --version
echo $SHELL         # deve apontar para o fish
```

### 3. Configure o Git
```bash
git config --global user.name "Seu Nome"
git config --global user.email "seu@email.com"
```

## 🐛 Problemas Comuns

### "Permission denied"
```bash
chmod +x install.sh
chmod +x install-from-config.sh
chmod +x uninstall.sh
```

### Paru não instala
Se Paru falhar durante a instalação, instale manualmente:
```bash
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..
rm -rf paru
```

### Docker não funciona
```bash
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
# Faça logout e login
```

### Falta espaço em disco
O script requer ~5-10GB de espaço livre durante a instalação.

## 📦 Estrutura dos Arquivos

```
arch-post-install/
├── install.sh                 # Script principal de instalação
├── install-from-config.sh     # Script customizável via packages.conf
├── packages.conf              # Arquivo de configuração de pacotes
├── uninstall.sh               # Script para desinstalar
├── kitty.conf                 # Config do terminal Kitty (Dracula Purple)
├── README.md                  # Documentação completa
└── QUICKSTART.md              # Este arquivo
```

## ⚡ Dicas Rápidas

- **Acelere installs**: Use Paru em vez de Pacman para AUR (mais rápido)
- **Monitorar progresso**: Execute em um terminal multiplexado (tmux/screen)
- **Verificar logs**: Os logs do script estão no terminal
- **Reinstalar um pacote**: `sudo pacman -S nome-do-pacote`
- **Limpar cache**: `sudo pacman -Sc`

## 📚 Próximos Passos

1. Personalize sua configuração de shell (Fish)
2. Configure Git: `git config --global user.name "Seu Nome"`
3. Autentique no GitHub/GitLab se necessário
4. Instale extensões/plugins para suas ferramentas

## 🔗 Recursos Úteis

- [Arch Wiki](https://wiki.archlinux.org/)
- [Fish Shell Docs](https://fishshell.com/docs/current/)
- [Flatpak](https://flatpak.org/)
- [Paru GitHub](https://github.com/morganamilo/paru)

---

**Precisa de ajuda?** Verifique o README.md para documentação completa.

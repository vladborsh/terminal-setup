# Terminal Setup

Automated setup script for macOS terminal with modern tools, themes, and configurations.

## What Gets Installed

### Applications
- **iTerm2** - Modern terminal emulator
- **Snazzy theme** - Color scheme for iTerm2

### Fonts
- **MesloLGS NF** - Nerd Font for Powerline symbols

### Tools
- **zsh** - Modern shell
- **tmux** - Terminal multiplexer
- **fzf** - Fuzzy finder
- **ripgrep** - Fast grep alternative
- **bat** - Better cat with syntax highlighting
- **fd** - Better find alternative
- **eza** - Modern ls replacement
- **git** - Version control

### Shell Framework & Theme
- **Oh My Zsh** - Zsh configuration framework
- **Powerlevel10k** - Modern zsh theme

### Zsh Plugins
- **zsh-autosuggestions** - Fish-like autosuggestions
- **zsh-syntax-highlighting** - Syntax highlighting for commands
- **fzf-tab** - Better tab completion with fzf

## Prerequisites

- macOS (any version)
- Internet connection
- Admin privileges for installing applications

## Installation

### Option 1: Quick Install (Recommended)

Run directly from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/vladborsh/terminal-setup/main/setup.sh | bash
```

### Option 2: Clone and Run

```bash
# Clone the repository
git clone https://github.com/vladborsh/terminal-setup.git

# Navigate to the directory
cd terminal-setup

# Make script executable
chmod +x setup.sh

# Run the script
./setup.sh
```

## Post-Installation Steps

After the script completes, follow these steps:

1. **Configure iTerm2**
   - Open iTerm2
   - Go to **Preferences → Profiles → Text**
   - Change font to **MesloLGS NF** (size 12-14 recommended)
   - The Snazzy color scheme will auto-import when opened

2. **Restart Terminal**
   - Close and reopen iTerm2
   - Powerlevel10k configuration wizard will launch automatically
   - Follow the prompts to customize your prompt

3. **Start tmux** (optional)
   ```bash
   tmux
   ```

## Configuration Details

### Shell Aliases

The script adds these convenient aliases:
- `cat` → `bat` (syntax-highlighted cat)
- `ls` → `eza` (modern ls)
- `ll` → `eza -l` (long listing)
- `la` → `eza -la` (all files, long listing)

### Tmux Configuration

- **Prefix**: Changed from `Ctrl+b` to `Ctrl+a`
- **Mouse support**: Enabled
- **Split shortcuts**:
  - `Ctrl+a |` - Vertical split
  - `Ctrl+a -` - Horizontal split

### Files Modified

- `~/.zshrc` - Zsh configuration (custom block appended)
- `~/.tmux.conf` - Tmux configuration (overwritten)

## Troubleshooting

### Homebrew Not in PATH

If `brew` command is not found after installation:

```bash
# For Apple Silicon (M1/M2/M3)
eval "$(/opt/homebrew/bin/brew shellenv)"

# For Intel Macs
eval "$(/usr/local/bin/brew shellenv)"
```

### Powerlevel10k Not Loading

Make sure `~/.p10k.zsh` exists and restart your terminal. If the wizard didn't run:

```bash
p10k configure
```

### Plugins Not Working

Restart your terminal or manually source:

```bash
source ~/.zshrc
```

## Re-running the Script

⚠️ **Note**: Currently, running the script multiple times will append duplicate configuration to `.zshrc`. If you need to re-run:

1. Backup your `.zshrc` first
2. Remove the custom block between markers before re-running
3. Or manually edit after re-running

## Uninstallation

To remove installed packages:

```bash
# Remove applications
brew uninstall --cask iterm2 font-meslo-lg-nerd-font

# Remove tools
brew uninstall zsh tmux fzf ripgrep bat fd eza git powerlevel10k

# Remove Oh My Zsh
rm -rf ~/.oh-my-zsh

# Restore configs (if you have backups)
# mv ~/.zshrc.backup ~/.zshrc
# mv ~/.tmux.conf.backup ~/.tmux.conf
```

## Contributing

Feel free to submit issues or pull requests for improvements!

## License

MIT

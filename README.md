# Terminal Setup

Automated setup script for macOS terminal with modern tools, themes, and configurations.
For Windows 11, see [Windows 11](#windows-11).

## What Gets Installed

### Applications
- **Ghostty** - Terminal emulator (Meslo Nerd Font, Catppuccin Mocha)

### Fonts
- **Meslo Nerd Font** (`MesloLGS Nerd Font Mono`) - Nerd Font for Powerline symbols

### Tools
- **tmux** - Terminal multiplexer
- **fzf** - Fuzzy finder
- **ripgrep** - Fast grep alternative
- **bat** - Better cat with syntax highlighting
- **fd** - Better find alternative
- **eza** - Modern ls replacement
- **git** - Version control
- **jq** - JSON processor (used to merge Claude settings)
- **NVM + Node.js LTS**

### Shell Framework & Theme
- **Oh My Zsh** - Zsh configuration framework
- **Powerlevel10k** - Modern zsh theme

### Zsh Plugins
- **zsh-autosuggestions** - Fish-like autosuggestions
- **zsh-syntax-highlighting** - Syntax highlighting for commands
- **zsh-history-substring-search** - History search with ↑/↓
- **fzf-tab** - Better tab completion with fzf

### Claude Code (optional, asked during setup)
- **Claude Code** - installed with the native installer (`~/.local/bin/claude`)
- **`claude/settings.json`** - merged into `~/.claude/settings.json` (model, effort, theme, status line, plugins). Existing keys such as hooks are kept.
- **ccstatusline** - status line; config from `claude/ccstatusline.json` → `~/.config/ccstatusline/settings.json`
- **Plugin** - `ui-ux-pro-max` from `nextlevelbuilder/ui-ux-pro-max-skill`
- **Skills** (via `npx skills`) - `mattpocock/skills` (grill-me, grill-with-docs, grilling, to-questionnaire, wait-what), `vercel-labs/skills` (find-skills), optionally `stablyai/orca` (orca-cli, orchestration, computer-use)

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

The script re-runs itself from a downloaded copy so prompts read from the terminal; config files are fetched from this repo.

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

1. **Open Ghostty** - font and theme are already set in `~/.config/ghostty/config`

2. **Restart Terminal**
   - Close and reopen Ghostty
   - Powerlevel10k configuration wizard will launch automatically
   - Follow the prompts to customize your prompt

3. **Log in to Claude Code** (if installed): run `claude`

4. **Start tmux** (optional)
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

- **Copy mode keys**: vi
- **Mouse support**: Enabled

### Files Modified

Every overwritten file is first backed up as `<file>.bak.<timestamp>`.

- `~/.zshrc` - custom block between markers (replaced on re-run)
- `~/.zprofile` - Homebrew `shellenv` block (replaced on re-run)
- `~/.tmux.conf` - overwritten
- `~/.config/ghostty/config` - overwritten
- `~/.claude/settings.json` - merged with `claude/settings.json`
- `~/.config/ccstatusline/settings.json` - overwritten

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

The script is safe to re-run: managed blocks in `~/.zshrc` and `~/.zprofile` are replaced, not duplicated, and already installed tools are skipped.

## Windows 11

`setup.ps1` sets up the same environment natively in PowerShell 7 + Windows Terminal (no WSL).

### Install

Run from a normal (non-admin) PowerShell window:

```powershell
irm https://raw.githubusercontent.com/vladborsh/terminal-setup/main/setup.ps1 | iex
```

Or clone and run:

```powershell
git clone https://github.com/vladborsh/terminal-setup.git
cd terminal-setup
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

The script needs `winget` (App Installer, preinstalled on Windows 11). When started from Windows PowerShell 5.1 it installs PowerShell 7 and re-runs itself there.

### macOS → Windows

| macOS | Windows |
|---|---|
| Homebrew | winget (apps) + Scoop (CLI tools) |
| Ghostty | Windows Terminal (PowerShell 7 default profile, Catppuccin Mocha scheme) |
| zsh + Oh My Zsh + Powerlevel10k | PowerShell 7 + Oh My Posh (`catppuccin_mocha` theme) |
| zsh-autosuggestions, history-substring-search, syntax-highlighting | PSReadLine (history predictions, ↑/↓ search) |
| fzf-tab, fzf key bindings | PSFzf (Tab, Ctrl+T, Ctrl+R) |
| nvm | NVM for Windows |
| tmux | not installed — use Windows Terminal panes |
| osxkeychain | Git Credential Manager |

Tools (fzf, ripgrep, bat, fd, eza, git, jq, python), aliases, git config and the Claude Code part (native installer, settings merge, ccstatusline, plugin, skills) match `setup.sh`. `CLAUDE_CODE_GIT_BASH_PATH` is set to Scoop's Git Bash.

### Files modified

Every overwritten file is first backed up as `<file>.bak.<timestamp>`.

- `$PROFILE` (`Documents\PowerShell\Microsoft.PowerShell_profile.ps1`) - custom block between markers (replaced on re-run)
- Windows Terminal `settings.json` - default profile, font, color scheme
- `~\.config\oh-my-posh\catppuccin_mocha.omp.json` - downloaded theme
- `~\.claude\settings.json` - merged with `claude/settings.json`
- `~\.config\ccstatusline\settings.json` - overwritten

## Updating the Claude config in this repo

After changing Claude settings locally, export the portable part (hooks and machine-specific keys are left out on purpose):

```bash
jq '{model, effortLevel, theme, statusLine, enabledPlugins, extraKnownMarketplaces, skipDangerousModePermissionPrompt, crossSessionInbound, agentPushNotifEnabled}' ~/.claude/settings.json > claude/settings.json
jq 'del(.installation)' ~/.config/ccstatusline/settings.json > claude/ccstatusline.json
```

## Uninstallation

To remove installed packages:

```bash
# Remove applications
brew uninstall --cask ghostty font-meslo-lg-nerd-font

# Remove tools
brew uninstall tmux fzf ripgrep bat fd eza jq powerlevel10k zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search

# Remove Oh My Zsh
rm -rf ~/.oh-my-zsh

# Restore configs (if you have backups)
# mv ~/.zshrc.bak.<timestamp> ~/.zshrc
# mv ~/.tmux.conf.bak.<timestamp> ~/.tmux.conf
```

## Contributing

Feel free to submit issues or pull requests for improvements!

## License

MIT

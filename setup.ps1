#Requires -Version 5.1
<#
.SYNOPSIS
  Windows 11 developer terminal environment setup (counterpart of setup.sh).
.DESCRIPTION
  Installs and configures: PowerShell 7, Windows Terminal, Scoop, CLI tools
  (git, fzf, ripgrep, bat, fd, eza, jq, oh-my-posh), Meslo Nerd Font,
  PSReadLine, Terminal-Icons, PSFzf, NVM for Windows, Node.js LTS,
  and optionally Claude Code with its config, plugins and skills.
  Run as a normal (non-admin) user. Safe to re-run.
#>

$ErrorActionPreference = 'Stop'

$RepoRaw             = 'https://raw.githubusercontent.com/vladborsh/terminal-setup/main'
$CcstatuslineVersion = '2.2.19'
$FontFace            = 'MesloLGS Nerd Font Mono'
$Pwsh7ProfileGuid    = '{574e775e-4f2a-5b96-ac1e-a2962a402336}'

# ─── helpers ─────────────────────────────────────────────────────────────────
function Log  { Write-Host "`n[INFO] $args" -ForegroundColor Green }
function Warn { Write-Host "`n[WARN] $args" -ForegroundColor Yellow }

function Refresh-Env {
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
              [Environment]::GetEnvironmentVariable('Path', 'User')
  foreach ($name in 'NVM_HOME', 'NVM_SYMLINK') {
    $value = [Environment]::GetEnvironmentVariable($name, 'User')
    if (-not $value) { $value = [Environment]::GetEnvironmentVariable($name, 'Machine') }
    if ($value) { Set-Item "env:$name" $value }
  }
}

# Run a native command; warn instead of aborting when it fails.
function Try-Run([string]$What, [scriptblock]$Block) {
  $global:LASTEXITCODE = 0
  try {
    & $Block | Out-Host
    if ($LASTEXITCODE) { throw "exit code $LASTEXITCODE" }
    return $true
  } catch {
    Warn "Could not $What ($_)."
    return $false
  }
}

function Backup([string]$Path) {
  if (Test-Path $Path) { Copy-Item $Path "$Path.bak.$(Get-Date -Format yyyyMMddHHmmss)" }
}

# Replace the block between markers (or append it) so re-runs stay idempotent.
function Write-Block([string]$Path, [string]$Begin, [string]$End, [string]$Content) {
  $dir = Split-Path $Path -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $text = if (Test-Path $Path) { Get-Content $Path -Raw } else { '' }
  if ($null -eq $text) { $text = '' }
  if ($text.Contains($Begin)) {
    Backup $Path
    $pattern = '(?s)\r?\n?' + [regex]::Escape($Begin) + '.*?' + [regex]::Escape($End) + '\r?\n?'
    $text = [regex]::Replace($text, $pattern, "`n")
  }
  $text = $text.TrimEnd()
  if ($text) { $text += "`n`n" }
  Set-Content -Path $Path -Value "$text$Begin`n$Content`n$End" -Encoding utf8
}

function Winget-Install([string]$Id, [string]$Name) {
  winget list --id $Id --exact --accept-source-agreements *> $null
  if ($LASTEXITCODE -eq 0) { Log "$Name already installed."; return }
  Log "Installing $Name..."
  Try-Run "install $Name" {
    winget install --id $Id --source winget --exact --silent --accept-package-agreements --accept-source-agreements
  } | Out-Null
  Refresh-Env
}

if ($env:OS -ne 'Windows_NT') {
  Warn "This script is designed for Windows."
  exit 1
}

# ─── Re-launch under PowerShell 7 ────────────────────────────────────────────
# $PROFILE and Install-Module differ between Windows PowerShell 5.1 and pwsh 7,
# so everything below must run in pwsh 7.
if ($PSVersionTable.PSVersion.Major -lt 7) {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Warn "winget not found. Install 'App Installer' from the Microsoft Store, then re-run this script."
    exit 1
  }
  Winget-Install 'Microsoft.PowerShell' 'PowerShell 7'
  $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
  if (-not $pwsh) {
    Warn "pwsh not found in PATH. Open a new terminal and re-run this script with: pwsh -File setup.ps1"
    exit 1
  }
  # Piped through `irm | iex`, there is no script file to re-run, so download one.
  $self = $PSCommandPath
  if (-not $self) {
    $self = Join-Path $env:TEMP 'terminal-setup.ps1'
    Invoke-RestMethod "$RepoRaw/setup.ps1" -OutFile $self
  }
  Log "Re-launching under PowerShell 7..."
  & $pwsh.Source -NoProfile -ExecutionPolicy Bypass -File $self
  exit $LASTEXITCODE
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
  IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
  Warn "Running as Administrator. Scoop refuses to install as admin; re-run from a normal terminal."
  exit 1
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Warn "winget not found. Install 'App Installer' from the Microsoft Store, then re-run this script."
  exit 1
}

# Use repo files next to the script, or download them when they are missing.
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { $null }
$TmpDir    = Join-Path ([IO.Path]::GetTempPath()) "terminal-setup-$PID"

function Repo-File([string]$Rel) {
  if ($ScriptDir -and (Test-Path (Join-Path $ScriptDir $Rel))) {
    return Join-Path $ScriptDir $Rel
  }
  $dest = Join-Path $TmpDir $Rel
  New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
  Invoke-RestMethod "$RepoRaw/$Rel" -OutFile $dest
  return $dest
}

# ─── winget apps ─────────────────────────────────────────────────────────────
Winget-Install 'Microsoft.PowerShell'      'PowerShell 7'
Winget-Install 'Microsoft.WindowsTerminal' 'Windows Terminal'

# ─── Scoop ───────────────────────────────────────────────────────────────────
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
  Log "Installing Scoop..."
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
  Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
  Refresh-Env
} else {
  Log "Scoop already installed."
}

# ─── CLI tools ───────────────────────────────────────────────────────────────
Log "Installing CLI tools via Scoop..."
# git first: scoop needs it for buckets and updates.
Try-Run 'install git' { scoop install git } | Out-Null
Try-Run 'install CLI tools' { scoop install fzf ripgrep bat fd eza jq python oh-my-posh } | Out-Null
Refresh-Env

# ─── Meslo Nerd Font ─────────────────────────────────────────────────────────
$fontInstalled = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Fonts", "$env:WINDIR\Fonts" `
                   -Filter 'MesloLGSNerdFontMono*' -ErrorAction SilentlyContinue
if (-not $fontInstalled) {
  Log "Installing Meslo Nerd Font..."
  Try-Run 'install Meslo Nerd Font' { oh-my-posh font install meslo --user } | Out-Null
} else {
  Log "Meslo Nerd Font already installed."
}

# ─── Git configuration ───────────────────────────────────────────────────────
Log "Configuring git..."
$currentGitName  = git config --global user.name  2>$null
$currentGitEmail = git config --global user.email 2>$null

if (-not $currentGitName) {
  $gitName = Read-Host "  Enter your git user name"
  if ($gitName) { git config --global user.name $gitName }
} else {
  Log "Git user.name already set: $currentGitName"
}

if (-not $currentGitEmail) {
  $gitEmail = Read-Host "  Enter your git email"
  if ($gitEmail) { git config --global user.email $gitEmail }
} else {
  Log "Git user.email already set: $currentGitEmail"
}

git config --global init.defaultBranch main
git config --global credential.helper manager

# ─── Oh My Posh theme ────────────────────────────────────────────────────────
Log "Downloading Oh My Posh Catppuccin Mocha theme..."
$poshTheme = "$HOME\.config\oh-my-posh\catppuccin_mocha.omp.json"
New-Item -ItemType Directory -Path (Split-Path $poshTheme -Parent) -Force | Out-Null
try {
  Invoke-RestMethod 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/catppuccin_mocha.omp.json' -OutFile $poshTheme
} catch {
  Warn "Could not download the Oh My Posh theme ($_)."
}

# ─── PowerShell modules ──────────────────────────────────────────────────────
Log "Installing PowerShell modules..."
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
foreach ($module in 'PSReadLine', 'Terminal-Icons', 'PSFzf') {
  try {
    Install-Module -Name $module -Repository PSGallery -Scope CurrentUser -Force -SkipPublisherCheck -AllowClobber
  } catch {
    Warn "Could not install module $module ($_)."
  }
}

# ─── NVM for Windows + Node.js LTS ───────────────────────────────────────────
Winget-Install 'CoreyButler.NVMforWindows' 'NVM for Windows'

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Log "Installing Node.js LTS via NVM..."
  # `nvm use` asks for elevation (UAC) to create its symlink.
  if (Try-Run 'install Node.js LTS' { nvm install lts }) {
    Try-Run 'activate Node.js LTS' { nvm use lts } | Out-Null
  }
  Refresh-Env
} else {
  Log "Node.js already installed: $(node --version)"
}

# ─── Claude Code (optional) ──────────────────────────────────────────────────
$localBin = "$HOME\.local\bin"
$env:Path = "$localBin;$env:Path"
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (($userPath -split ';') -notcontains $localBin) {
  [Environment]::SetEnvironmentVariable('Path', "$localBin;$userPath", 'User')
}

$installClaude = Read-Host "`n  Install Claude Code and its config? [y/N]"
if ($installClaude -match '^[Yy]$') {
  # Claude Code runs shell commands through Git Bash; point it at Scoop's copy.
  $gitBash = "$HOME\scoop\apps\git\current\bin\bash.exe"
  if (Test-Path $gitBash) {
    [Environment]::SetEnvironmentVariable('CLAUDE_CODE_GIT_BASH_PATH', $gitBash, 'User')
    $env:CLAUDE_CODE_GIT_BASH_PATH = $gitBash
  }

  if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Log "Installing Claude Code (native installer)..."
    # Child process: the installer script must not share this script's scope.
    Try-Run 'install Claude Code' {
      pwsh -NoProfile -ExecutionPolicy Bypass -Command 'irm https://claude.ai/install.ps1 | iex'
    } | Out-Null
  } else {
    Log "Claude Code already installed: $(claude --version)"
  }

  $hasNode = [bool](Get-Command npm -ErrorAction SilentlyContinue)
  if ($hasNode) {
    Log "Installing ccstatusline..."
    Try-Run 'install ccstatusline' { npm install -g "ccstatusline@$CcstatuslineVersion" } | Out-Null
  } else {
    Warn "npm not found; skipping ccstatusline and skills. Re-run this script after Node.js is set up."
  }
  $ccConfig = "$HOME\.config\ccstatusline\settings.json"
  New-Item -ItemType Directory -Path (Split-Path $ccConfig -Parent) -Force | Out-Null
  Backup $ccConfig
  Copy-Item (Repo-File 'claude/ccstatusline.json') $ccConfig -Force

  Log "Merging Claude settings into ~\.claude\settings.json..."
  $claudeSettings = "$HOME\.claude\settings.json"
  $repoSettings   = Repo-File 'claude/settings.json'
  New-Item -ItemType Directory -Path (Split-Path $claudeSettings -Parent) -Force | Out-Null
  if ((Test-Path $claudeSettings) -and (Get-Item $claudeSettings).Length -gt 0) {
    Backup $claudeSettings
    $merged = jq -s '.[0] * .[1]' $claudeSettings $repoSettings
    if ($LASTEXITCODE -eq 0) {
      Set-Content -Path $claudeSettings -Value $merged -Encoding utf8NoBOM
    } else {
      Warn "~\.claude\settings.json is not valid JSON; left unchanged. Merge $repoSettings manually."
    }
  } else {
    Copy-Item $repoSettings $claudeSettings -Force
  }

  if (Get-Command claude -ErrorAction SilentlyContinue) {
    Log "Installing Claude plugins..."
    Try-Run 'add marketplace ui-ux-pro-max-skill' {
      claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill
    } | Out-Null
    Try-Run 'install plugin ui-ux-pro-max. Run inside claude: /plugin' {
      claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill
    } | Out-Null
  }

  if ($hasNode) {
    Log "Installing agent skills..."
    Try-Run 'install mattpocock/skills' {
      npx -y skills add mattpocock/skills -g -a claude-code -y `
        --skill grill-me --skill grill-with-docs --skill grilling `
        --skill to-questionnaire --skill wait-what
    } | Out-Null
    Try-Run 'install vercel-labs/skills' {
      npx -y skills add vercel-labs/skills -g -a claude-code -y --skill find-skills
    } | Out-Null

    $installOrca = Read-Host "  Install Orca skills (orca-cli, orchestration, computer-use)? [y/N]"
    if ($installOrca -match '^[Yy]$') {
      Try-Run 'install stablyai/orca skills' {
        npx -y skills add stablyai/orca -g -a claude-code -y `
          --skill orca-cli --skill orchestration --skill computer-use
      } | Out-Null
    }
  }

  Log "Claude Code ready. Run 'claude' to log in."
} else {
  Log "Skipping Claude Code installation."
}

# ─── PowerShell profile ──────────────────────────────────────────────────────
Log "Updating PowerShell profile ($PROFILE)..."

Write-Block $PROFILE `
  '# ===== Custom terminal setup (generated by setup.ps1) =====' `
  '# ===== End custom terminal setup =====' `
  @'
$env:Path = "$HOME\.local\bin;$env:Path"

# Oh My Posh — Catppuccin Mocha theme
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
  oh-my-posh init pwsh --config "$HOME\.config\oh-my-posh\catppuccin_mocha.omp.json" | Invoke-Expression
}

# PSReadLine — autosuggestions and history substring search on ↑/↓
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Terminal-Icons — file/folder icons in listings
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

# PSFzf — Ctrl+T: files, Ctrl+R: history, Tab: fzf completion
if (Import-Module PSFzf -PassThru -ErrorAction SilentlyContinue) {
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
  Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
}

# Aliases (built-in ls/cat aliases win over functions, so drop them first)
Remove-Item Alias:ls, Alias:cat -Force -ErrorAction SilentlyContinue
function cat { bat @args }
function ls  { eza @args }
function ll  { eza -l @args }
function la  { eza -la @args }
'@

# ─── Windows Terminal ────────────────────────────────────────────────────────
Log "Configuring Windows Terminal..."
$wtSettingsPath = @(
  (Get-ChildItem "$env:LOCALAPPDATA\Packages" -Filter 'Microsoft.WindowsTerminal_*' -Directory -ErrorAction SilentlyContinue |
    ForEach-Object { Join-Path $_.FullName 'LocalState\settings.json' }),
  "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
) | Where-Object { $_ -and (Test-Path (Split-Path $_ -Parent)) } | Select-Object -First 1

if ($wtSettingsPath) {
  try {
    if (Test-Path $wtSettingsPath) {
      Backup $wtSettingsPath
      $wt = Get-Content $wtSettingsPath -Raw | ConvertFrom-Json
    } else {
      # Windows Terminal fills in everything missing from a partial settings file.
      $wt = [PSCustomObject]@{}
    }
    if (-not $wt.PSObject.Properties['profiles']) {
      $wt | Add-Member profiles ([PSCustomObject]@{})
    }
    if (-not $wt.profiles.PSObject.Properties['defaults']) {
      $wt.profiles | Add-Member defaults ([PSCustomObject]@{})
    }
    $wt.profiles.defaults | Add-Member font ([PSCustomObject]@{ face = $FontFace; size = 13 }) -Force
    $wt.profiles.defaults | Add-Member colorScheme 'Catppuccin Mocha' -Force
    $wt | Add-Member defaultProfile $Pwsh7ProfileGuid -Force

    $mocha = [PSCustomObject][ordered]@{
      name                = 'Catppuccin Mocha'
      cursorColor         = '#F5E0DC'
      selectionBackground = '#585B70'
      background          = '#1E1E2E'
      foreground          = '#CDD6F4'
      black               = '#45475A'
      red                 = '#F38BA8'
      green               = '#A6E3A1'
      yellow              = '#F9E2AF'
      blue                = '#89B4FA'
      purple              = '#F5C2E7'
      cyan                = '#94E2D5'
      white               = '#BAC2DE'
      brightBlack         = '#585B70'
      brightRed           = '#F38BA8'
      brightGreen         = '#A6E3A1'
      brightYellow        = '#F9E2AF'
      brightBlue          = '#89B4FA'
      brightPurple        = '#F5C2E7'
      brightCyan          = '#94E2D5'
      brightWhite         = '#A6ADC8'
    }
    $schemes = @($wt.schemes | Where-Object { $_ -and $_.name -ne 'Catppuccin Mocha' }) + $mocha
    $wt | Add-Member schemes $schemes -Force

    $wt | ConvertTo-Json -Depth 32 | Set-Content $wtSettingsPath -Encoding utf8NoBOM
    Log "Windows Terminal: PowerShell 7 default, $FontFace 13, Catppuccin Mocha."
  } catch {
    Warn "Could not update Windows Terminal settings ($_). Set manually: font '$FontFace' 13, color scheme Catppuccin Mocha."
  }
} else {
  Warn "Windows Terminal settings folder not found. Set manually: font '$FontFace' 13, color scheme Catppuccin Mocha."
}

if (Test-Path $TmpDir) { Remove-Item $TmpDir -Recurse -Force }

Log "Done! Next steps:"
Write-Host "  1) Close this window and open Windows Terminal — PowerShell 7 with Meslo Nerd Font and Catppuccin Mocha."
Write-Host "  2) Run 'claude' to log in to Claude Code."
Write-Host "  3) If Node.js was skipped, run in a new terminal: nvm install lts; nvm use lts — then re-run this script."
Write-Host "  4) No tmux on Windows: use Windows Terminal panes (Alt+Shift+= / Alt+Shift+-)."

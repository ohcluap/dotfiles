#!/bin/bash
set -e

echo "========================================="
echo "   🚀 Mac Setup Script Starting..."
echo "========================================="

###############################################################################
# Dock Cleanup
###############################################################################
echo ">> Cleaning up Dock..."
defaults write com.apple.dock persistent-apps -array
killall Dock || true

###############################################################################
# Hot Corners
###############################################################################
echo ">> Setting hot corners..."
# Bottom left = Sleep
defaults write com.apple.dock wvous-bl-corner -int 10
defaults write com.apple.dock wvous-bl-modifier -int 0

# Bottom right = Mission Control (all windows)
defaults write com.apple.dock wvous-br-corner -int 3
defaults write com.apple.dock wvous-br-modifier -int 0
killall Dock || true

###############################################################################
# Security Settings
###############################################################################
echo ">> Requiring password after two seconds after sleep or screen saver..."
# askForPasswordDelay is in seconds
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 2
defaults -currentHost write com.apple.screensaver askForPassword -int 1
defaults -currentHost write com.apple.screensaver askForPasswordDelay -int 2

echo ">> Setting screen to dim after two minutes..."
# For battery
sudo pmset -b displaysleep 2  # 1 minute is closest; macOS only accepts whole minutes
# For charger
sudo pmset -c displaysleep 2

###############################################################################
# Trackpad Gestures
###############################################################################
echo ">> Configuring trackpad gestures..."
defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerHorizSwipeGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 2
defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool true
killall Dock SystemUIServer || true

###############################################################################
# Appearance
###############################################################################
echo ">> Setting Light Mode..."
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false'

###############################################################################
# Homebrew
###############################################################################
echo ">> Checking Homebrew..."
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -d "/opt/homebrew/bin" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -d "/usr/local/bin" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
else
    echo "Homebrew already installed."
    if [[ -d "/opt/homebrew/bin" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -d "/usr/local/bin" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

###############################################################################
# Apps & Developer Tools
###############################################################################
echo ">> Installing apps and developer tools..."
brew install git python node go postgresql asdf
brew install --cask docker slack spotify visual-studio-code raycast
brew services start postgresql || true

###############################################################################
# Oh My Zsh
###############################################################################
echo ">> Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh already installed."
fi

###############################################################################
# Powerlevel10k + Zsh Plugins
###############################################################################
echo ">> Installing Powerlevel10k + Zsh plugins..."
brew install romkatv/powerlevel10k/powerlevel10k zsh-autosuggestions zsh-history-substring-search

# Paths
P10K_PATH="$(brew --prefix powerlevel10k)/powerlevel10k.zsh-theme"
AUTO_PATH="$(brew --prefix zsh-autosuggestions)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
HIST_PATH="$(brew --prefix zsh-history-substring-search)/share/zsh-history-substring-search/zsh-history-substring-search.zsh"
ZSHRC=~/.zshrc

# Powerlevel10k
if [[ -f "$P10K_PATH" ]] && ! grep -q "powerlevel10k.zsh-theme" $ZSHRC; then
    echo "source $P10K_PATH" >> $ZSHRC
fi

# Autosuggestions
if [[ -f "$AUTO_PATH" ]] && ! grep -q "zsh-autosuggestions" $ZSHRC; then
    echo "source $AUTO_PATH" >> $ZSHRC
fi

# History substring search
if [[ -f "$HIST_PATH" ]] && ! grep -q "zsh-history-substring-search" $ZSHRC; then
    cat <<EOF >> $ZSHRC

# History substring search (up/down only through matching commands)
source $HIST_PATH
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
EOF
fi

# 1Password Oh My Zsh plugin
echo ">> Installing 1Password Oh My Zsh plugin..."
OMZ_CUSTOM="$HOME/.oh-my-zsh/custom"
PLUGIN_DIR="$OMZ_CUSTOM/plugins/1password"
if ! grep -q "1password" $ZSHRC; then
    sed -i '' 's/^plugins=(\(.*\))/plugins=(\1 1password)/' $ZSHRC || true
fi
brew install --cask 1password/tap/1password-cli

# Auto-run p10k configure
if ! grep -q "p10k configure" $ZSHRC; then
    cat <<'EOF' >> $ZSHRC

# Run Powerlevel10k config on first launch
if [[ ! -f ~/.p10k.zsh ]] && command -v p10k &>/dev/null; then
  p10k configure
fi
EOF
fi

###############################################################################
# Finder Preferences
###############################################################################
echo ">> Configuring Finder..."
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
killall Finder || true

###############################################################################
# Finished
###############################################################################
echo "========================================="
echo "   ✅ Mac Setup Script Complete!"
echo "   Restart terminal to apply all Zsh/Powerlevel10k/Oh My Zsh changes."
echo "   Manual steps: Docker Desktop first launch, add fingerprints."
echo "========================================="


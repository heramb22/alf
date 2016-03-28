#!/usr/bin/env zsh
#
# Script for bootstraping our baseline shell environment.
#
# Author:
#   Larry Gordon
#
# License:
#   The MIT License (MIT) <http://psyrendust.mit-license.org/2014/license.html>
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------------------------
# Small helper function to get Antigen's clone dir for a given repo url
__alf-get-antigen-clone-dir() {
  local url="$1"
  if [[ $# > 1 ]]; then
    local branch="$(echo $2 | cut -d= -f2)"
    if [[ ! -z $branch ]]; then
        url="$url|$branch"
    fi
  fi
  echo "$url" | sed \
              -e 's./.-SLASH-.g' \
              -e 's.:.-COLON-.g' \
              -e 's.|.-PIPE-.g'
}

# Check if a formula is installed in homebrew
function _app-is-installed() {
  apps=(
    "/Applications"
    "$HOME/Applications"
  )
  for app in $apps; do
    if [[ -n $(ls /Applications 2>/dev/null | grep "^${1}$") ]]; then
      echo 1
      return
    fi
  done
}

# Check if a formula is installed in homebrew
function _brew-is-installed() {
  echo $(brew list 2>/dev/null | grep "^${1}$")
}

# Check if a cask application is installed
function _cask-is-installed() {
  echo $(brew cask list 2>/dev/null | grep "^${1}$")
}

# Check if a formula is tapped in homebrew
function _brew-is-tapped() {
  echo $(brew tap 2>/dev/null | grep "^${1}$")
}

# Print pretty colors to stdout in Cyan.
function ppinfo() {
  while getopts ":i" opt; do
    [[ $opt == "i" ]] && has_option=1
  done
  if [[ -n $has_option ]]; then
    shift && printf '\033[0;36m%s\033[0m' "$@"
  else
    printf '\033[0;36m%s\033[0m\n' "$@"
  fi
}

# Print pretty colors to stdout in Green.
function ppsuccess() {
  while getopts ":i" opt; do
    [[ $opt == "i" ]] && has_option=1
  done
  if [[ -n $has_option ]]; then
    shift && printf '\033[0;32m%s\033[0m' "$@"
  else
    printf '\033[0;32m%s\033[0m\n' "$@"
  fi
}

# Print pretty colors to stdout in Purple.
function ppemphasis() {
  while getopts ":i" opt; do
    [[ $opt == "i" ]] && has_option=1
  done
  if [[ -n $has_option ]]; then
    shift && printf '\033[0;35m%s\033[0m' "$@"
  else
    printf '\033[0;35m%s\033[0m\n' "$@"
  fi
}

# Print pretty colors to stdout in Brown.
function ppwarning() {
  while getopts ":i" opt; do
    [[ $opt == "i" ]] && has_option=1
  done
  if [[ -n $has_option ]]; then
    shift && printf '\033[0;33m%s\033[0m' "$@"
  else
    printf '\033[0;33m%s\033[0m\n' "$@"
  fi
}

# Print pretty colors to stdout in Red.
function ppdanger() {
  while getopts ":i" opt; do
    [[ $opt == "i" ]] && has_option=1
  done
  if [[ -n $has_option ]]; then
    shift && printf '\033[0;31m%s\033[0m' "$@"
  else
    printf '\033[0;31m%s\033[0m\n' "$@"
  fi
}


# ------------------------------------------------------------------------------
# Do some platform checks so we don't have to keep doing it later
# ------------------------------------------------------------------------------
if [[ $('uname') == *Darwin* ]]; then
  # We are using OS X
  export PLATFORM_IS_MAC=1

elif [[ $('uname') == *CYGWIN* ]]; then
  # We are using Cygwin in Windows
  export PLATFORM_IS_CYGWIN=1
  # We are also in a virtualized Windows environment
  if [[ -f $(find /cygdrive/z -maxdepth 1 -type f -name ".zshrc.lnk") ]]; then
    export PLATFORM_IS_VM=1
    export ALF_HOST="/cygdrive/z/.alf"
  fi

elif [[ $('uname') == *Linux* ]]; then
  # We are using Linux
  export PLATFORM_IS_LINUX=1
fi
# Add support for all systems
export PLATFORM_IS_ALL=1



# ------------------------------------------------------------------------------
# Setup environment paths and folders
# ------------------------------------------------------------------------------
export ALF_CUSTOM="$HOME/.alf"
export ALF_CONFIG="$ALF_CUSTOM/config"
export ADOTDIR="$ALF_CUSTOM/antigen"
export ALF_URL="https://github.com/psyrendust/alf.git"
export ALF_SRC="$ADOTDIR/repos/$(__alf-get-antigen-clone-dir $ALF_URL $ALF_BRANCH)"
export ALF_BACKUP_FOLDER="$ALF_CUSTOM/backup/$(date '+%Y%m%d')"



# ------------------------------------------------------------------------------
# Ask for the administrator password upfront
# ------------------------------------------------------------------------------
if [[ -n $PLATFORM_IS_MAC ]]; then
  ppinfo "Ask for the administrator password upfront"
  sudo -v


  # Keep-alive: update existing `sudo` time stamp until
  # `baseline.zsh` has finished
  ppinfo "Keep-alive: update existing \`sudo\` time stamp until \`baseline.zsh\` has finished"
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


  # Let's do some admin type stuff
  # Add yourself to the `wheel` group
  ppinfo "Add yourself to the \`wheel\` group"
  sudo dseditgroup -o edit -a $(echo $USER) -t user wheel


  # add myself to staff group
  ppinfo "add myself to \`staff\` group"
  sudo dseditgroup -o edit -a $(echo $USER) -t user staff
fi

# # ------------------------------------------------------------------------------
# # Let's make sure we are using Zsh
# # ------------------------------------------------------------------------------
# if [[ -z $(echo $SHELL | grep '/usr/local/bin/zsh\|/bin/zsh') ]]; then
#   ppinfo "Change root shell to /bin/zsh"
#   sudo chsh -s /bin/zsh

#   ppinfo "Change local shell to /bin/zsh"
#   chsh -s /bin/zsh
# fi


# Define a different branch for Alf, helpful for doing dev
if [[ $# -ge 1 ]]; then
  echo "$1" > "$ALF_CONFIG/branch"
else
  [[ -s "$ALF_CONFIG/branch" ]] && rm "$ALF_CUSTOM/branch"
fi
[[ -s "$ALF_CONFIG/branch" ]] && export ALF_BRANCH="--branch=$(echo `cat $ALF_CONFIG/branch`)"

# Setup a default theme
export ALF_THEME="sindresorhus/pure"


ppemphasis "ALF_SRC: $ALF_SRC"
mkdir -p -m 775 "$ADOTDIR"
mkdir -p -m 775 "$ALF_BACKUP_FOLDER"


# Ensure that "/usr/local/bin" exists and is added to the beginning of $PATH
ppinfo "Ensure that \"/usr/local/bin\" exists"
sudo mkdir -p -m 775 "/usr/local/bin"
if [[ -z $(echo $PATH | grep "^/usr/local/bin") ]]; then
  ppwarning "\"/usr/local/bin\" is not at the beginning of \$PATH"
  if [[ -z $(echo $PATH | grep "^/usr/local/bin") ]]; then
    ppinfo "Moving \"/usr/local/bin\" to the beginning of \$PATH"
    export PATH="/usr/local/bin:$(echo $PATH | sed 's/:\/usr\/local\/bin//g')"
  else
    ppinfo "Adding /usr/local/bin to the beginning of \$PATH"
    export PATH="/usr/local/bin:${PATH}"
  fi
fi

ppemphasis "Your \$PATH is now: $PATH"



# ------------------------------------------------------------------------------
# Backup your current configuration stuff in
# "$ALF_BACKUP_FOLDER".
# ------------------------------------------------------------------------------
ppinfo "Backing up your current configuration to: $ALF_BACKUP_FOLDER"
files_list=(
  .gemrc
  .gitconfig
  .gitignore_global
  .gitconfig-includes
  .zlogin
  .zlogout
  .zprofile
  .zshenv
  .zshrc
  .zshrcwork
  .zshrcuser
  .zsh-update
  .zsh_history
)
for file in ${files_list[@]}; do
  [[ -a $HOME/$file ]] && mv "$HOME/$file" "$ALF_BACKUP_FOLDER/$file"
done
# Remove
find $HOME -type f -maxdepth 1 -name ".zcompdump*" -exec rm {} \;



# ------------------------------------------------------------------------------
# Setup OS X
# ------------------------------------------------------------------------------
# Install Homebrew
if [[ -n $PLATFORM_IS_MAC ]]; then

  ppinfo "Checking for command line dev tools."
  if [[ ! -f "/Library/Developer/CommandLineTools/usr/bin/clang" ]]; then
    ppemphasis "Installing the Command Line Tools:"
    # Unattended Install
        # source: http://apple.stackexchange.com/questions/107307/how-can-i-install-the-command-line-tools-completely-from-the-command-line
        touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
        PROD=$(softwareupdate -l |
            grep "\*.*Command Line" |
            head -n 1 | awk -F"*" '{print $2}' |
            sed -e 's/^ *//' |
            tr -d '\n')
        softwareupdate -i "$PROD" -v;
  fi

  ppemphasis "Checking for homebrew..."
  if [[ -n $(brew --prefix 2>&1 | grep "not found") ]]; then
    ppdanger "Homebrew missing. Installing Homebrew..."
    # https://github.com/mxcl/homebrew/wiki/installation
    ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
  else
    ppsuccess "Homebrew already installed!"
  fi

  ppinfo "Check with brew doctor"
  brew doctor

  ppinfo "Make sure we’re using the latest Homebrew"
  brew update

  ppinfo "Upgrade any already-installed formulae"
  brew upgrade

  if [[ -z $(_brew-is-installed "bash") ]]; then
    ppinfo "Install the latest Bash"
    brew install bash
  fi

  if [[ -z $(_brew-is-installed "zsh") ]]; then
    ppinfo "Install the latest Zsh"
    brew install zsh
  fi

  if [[ -z $(cat /private/etc/shells | grep "/usr/local/bin/bash") ]]; then
    ppinfo "Add bash to the allowed shells list if it's not already there"
    sudo bash -c "echo /usr/local/bin/bash >> /private/etc/shells"
  fi
  if [[ -z $(cat /private/etc/shells | grep "/usr/local/bin/zsh") ]]; then
    ppinfo "Add zsh to the allowed shells list if it's not already there"
    sudo bash -c "echo /usr/local/bin/zsh >> /private/etc/shells"
  fi

  ppinfo "Change root shell to /usr/local/bin/zsh"
  sudo chsh -s /usr/local/bin/zsh

  ppinfo "Change local shell to /usr/local/bin/zsh"
  chsh -s /usr/local/bin/zsh

  ppinfo "Making sure that everything went well by checking"
  ppinfo "that we are using homebrew's Zsh."
  if [[ -n $(which zsh | grep "/usr/local/bin/zsh") ]]; then
    ppsuccess "Great, we are now using the latest version of Zsh!"
    ppsuccess "$(zsh --version)"
  else
    ppdanger "\$SHELL is not /usr/local/bin/zsh"
    return 1
  fi

  if [[ -z $(_brew-is-installed "brew-cask") ]]; then
    ppinfo "Install homebrew cask"
    brew tap phinze/cask
    brew install brew-cask
    brew tap caskroom/versions
  fi

  ppinfo "Install some cask apps"
  brew cask install iterm2 sublime-text-dev
fi

ppemphasis "ALF_CUSTOM: $ALF_CUSTOM"
ppemphasis "ALF_SRC: $ALF_SRC"
ppemphasis "ADOTDIR: $ADOTDIR"
ppemphasis "ALF_BACKUP_FOLDER: $ALF_BACKUP_FOLDER"

ppinfo "Installing Antigen"
git clone https://github.com/zsh-users/antigen "$ADOTDIR" 2>/dev/null


ppinfo "Sourcing Antigen"
source "$ADOTDIR/antigen.zsh"


ppinfo "Installing Oh My Zsh, Alf, Zsh Syntax Highlighting, and Pure"
antigen bundle fasd
antigen bundle $ALF_URL $ALF_BRANCH
antigen bundle $ALF_URL $ALF_BRANCH plugins/colored-man
antigen bundle $ALF_URL $ALF_BRANCH plugins/migrate
antigen bundle $ALF_URL $ALF_BRANCH plugins/utilities
antigen bundle $ALF_URL $ALF_BRANCH plugins/system
antigen bundle $ALF_URL $ALF_BRANCH plugins/sugar
antigen bundle $ALF_THEME
antigen bundle zsh-users/zaw
antigen bundle zsh-users/zsh-completions src
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-history-substring-search
source "$ZSH/oh-my-zsh.sh"
# Call apply functions for Alf and Antigen
alf apply
antigen apply

if [[ -n $PLATFORM_IS_MAC ]]; then
  # Copy over iTerm2 default preferences
  cp "$ALF_SRC/templates/config/iterm/com.googlecode.iterm2.plist" "$HOME/Library/Preferences/com.googlecode.iterm2.plist"
fi

ppinfo "Calling alf migrate and restarting terminal after completion."
alf migrate --restart

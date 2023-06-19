#!/usr/bin/env bash
# helper functions

command_exists () {
  type "$1" &> /dev/null ;
}

logm () {
  echo $*
}

read_default () {
  defaults read "$1" "$2" &> /dev/null;
}

upsert_default () {
  local domain="$1"
  local key="$2"
  local value="$3"
  local original=$(defaults read $domain $key)

  if [ "$original" != "$value" ]; then
    defaults write "$domain" "$key" "$value"
    return 0
  fi

  return 1
}

delete_default () {
  local domain="$1"
  local key="$2"

  if read_default "$domain" "$key"; then
    defaults delete "$domain" "$key"
    return 0
  fi

  return 1
}

string_in_file () {
  local string="$1"
  local file="$2"
  grep -q "$string" "$file"
}

# tasks

enable_filevault () {
  if ! fdesetup status | grep -q -E "FileVault is (On|Off, but will be enabled after the next restart)."; then
    logm "enable filevault"
    sudo fdesetup enable -user $USER
  fi
}

create_ssh () {
  local SSH_DIR=~/.ssh
  local SSH_GITHUB="$SSH_DIR/github"

  if ! [ -d "$SSH_DIR" ]; then
    logm "create .ssh directory"
    mkdir "$SSH_DIR"
    cp ssh_config "$SSH_DIR/config"
  fi

  if ! [ -f "$SSH_GITHUB" ]; then
    logm "generate a ssh key for github"
    ssh-keygen -t ed25519 -f "$SSH_GITHUB"
  fi
}

configure_git () {
  local GIT_EMAIL=""

  if ! [ -f ~/.gitconfig ]; then
    logm "config git"
    read -r -p 'Git Email Address: ' GIT_EMAIL
    git config --global user.name "$(id -F)"
    git config --global user.email "$GIT_EMAIL"

    git config --global push.default simple

    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.st status
    git config --global core.excludesfile "~/.gitignore_global"
  fi
}

configure_ui () {
  if delete_default "com.apple.dock" "persistent-apps"; then
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock "show-recents" -bool true
    logm "clean dock"
    killall -KILL Dock
  fi

  # disable dictation
  defaults write com.apple.HIToolbox -int 0

  if upsert_default "com.apple.menuextra.clock" "DateFormat" "EEE MMM d  h:mm "; then
    logm "set menu clock to show date"
    killall -KILL SystemUIServer
  fi

  if upsert_default "com.apple.menuextra.battery" "ShowPercent" "YES"; then
    logm "set menu battery to show percentage"
    killall -KILL SystemUIServer
  fi
}

configure_environment_variables () {
  local profile_file=~/.profile

  local enable_cli_color="export CLICOLOR=1"
  if ! string_in_file "$enable_cli_color" "$profile_file"; then
    logm "Enable CLI color"
    echo "$enable_cli_color" >> $profile_file
  fi

  source "$profile_file"
}

install_brew () {
  if ! command_exists brew; then
    logm "install homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew analytics off
  fi

  logm "update brew"
  brew update
  logm "install brewfile content"
  brew bundle --file=Brewfile

  # Enable fzf
  $(brew --prefix)/opt/fzf/install
}

# main
main () {  
  install_brew

  enable_filevault
  create_ssh
  configure_git
  configure_ui

  configure_environment_variables
}

main

command_exists () {
  type "$1" &> /dev/null ;
}

logm () {
  echo $*
}

enable_filevault () {
  if ! fdesetup status | grep $Q -E "FileVault is (On|Off, but will be enabled after the next restart)." &> /dev/null; then
    logm "enable filevault"
    sudo fdesetup enable -user $USER
  fi
}

create_ssh () {
  local SSH_DIR=~/.ssh
  local SSH_GITHUB="$SSH_DIR/github"

  if ! [ -d $SSH_DIR ]; then
    logm "create .ssh directory"
    mkdir $SSH_DIR
    cp ssh_config $SSH_DIR/config
  fi

  if ! [ -f $SSH_GITHUB ]; then
    logm "generate a ssh key for github"
    ssh-keygen -t rsa -b 4096 -f $SSH_GITHUB
  fi
}

configure_git () {
  local GIT_EMAIL=""

  if ! [ -f ~/.gitconfig ]; then
    logm "config git"
    read -r -p 'Git Email Address: ' GIT_EMAIL
    git config --global user.name "$(id -F)"
    git config --global user.email $GIT_EMAIL

    git config --global push.default simple

    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.st status
    git config --global core.excludesfile '~/.gitignore_global'
  fi
}

clean_dock () {
  local DOCK_LIST_DOMAIN="com.apple.dock"
  local DOCK_LIST_PERSISTENT_APPS="persistent-apps"

  if defaults read $DOCK_LIST_DOMAIN $DOCK_LIST_PERSISTENT_APPS &> /dev/null; then
    logm "clean dock"
    defaults delete DOCK_LIST_DOMAIN DOCK_LIST_PERSISTENT_APPS
    killall Dock
  fi
}

install_brew () {
  if ! command_exists brew; then
    logm "install homebrew"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  logm "install brewfile content"
  brew bundle --file=Brewfile
}

main () {
  enable_filevault
  create_ssh
  configure_git
  clean_dock
  install_brew
}

main

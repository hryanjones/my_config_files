#! /bin/bash

# stolen from http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEST="$HOME"
#BACKUP_DIR="/tmp/backup/`date +%s0`"
#mkdir -p $BACKUP_DIR

DRY_RUN="true"
if [ $# -ne 0 ]; then
  DRY_RUN="false"
  echo "Doing a dry run.  Will echo the actions to be taken (which can be applied manually).  If you want to do a real run include an argument, any argument."
fi

function handle_dry_run {
  if [ "$DRY_RUN" == "true" ]; then
    echo "$*"
  else
    $*
  fi
}

if [ ! -e $DEST ]; then
  CMD="mkdir -p $DEST"
  handle_dry_run $CMD
fi

cd $DIR

# Get the package manager (yum or apt-get)
which apt-get > /dev/null
if [ $? -eq 0 ];then
  PACK_MGR="apt-get"
else
  which yum > /dev/null
  if [ $? -eq 0 ];then
    PACK_MGR="yum"
  else
    echo "Couldn't find package manager (not apt-get or yum)"
    exit 1
  fi
fi

# bash included just so can install bashrc & aliases
PROGS_TO_CHECK="bash
vim
terminator
fish
chromium-browser
s3cmd
ipython
ruby
meld
git"

function check_program {
  which $1 > /dev/null
  if [ $? -ne 0 ]; then
    CMD="sudo $PACK_MGR -y install $1"
    handle_dry_run $CMD
  else
    remind_to_install_config_files $1
  fi
}

function remind_to_install_config_files {
  CONFIG_DIRS="" # need to initialize else things may be repeated
  case "$1" in
    bash)
      CONFIG_DIRS=".bashrc
.shell_path_additions.txt
.bash_aliases"
      ;;
    vim)
      #echo "Making sure submodules loaded"
      CMD="git submodule init"
      handle_dry_run $CMD
      CMD="git submodule update"
      handle_dry_run $CMD
      CONFIG_DIRS=`grep --color=never -o "\ \.vim.*bundle.*" .gitmodules | sed -e 's/^\ //'` # include all vim modules
      CONFIG_DIRS="$CONFIG_DIRS
.vimrc
.vim/after/ftplugin
.vim/autoload/pathogen.vim
.vim/fonts"
      ;;
    terminator)
      CONFIG_DIRS=.config/terminator/config
      ;;
    s3cmd)
      if [ ! -f $DEST/.s3cfg ]; then
        echo "#sign into the https://console.aws.amazon.com/s3/home to get S3 access keys"
      fi
      ;;
    chromium-browser)
      CONFIG_DIRS=".config/chromium/Unpacked_Extensions/highContrastChromeExtension"
      ;;
    fish)
      CONFIG_DIRS=".config/fish/config.fish
.config/fish/functions/fish_prompt.fish"
      ;;
    git)
      CONFIG_DIRS=".gitconfig
.gitignore_global"
      ;;
  esac
  for D in $CONFIG_DIRS; do
    if [ ! -e $D ]; then
      echo "$D is not present in $DIR -- SKIPPING"
      echo "CONSIDER DELETING $D FROM CONFIG FILES!!!!!!! (giving up now)"
      exit 1
    fi
    DEST_DIR=`dirname $DEST/$D`
    if [ ! -e $DEST_DIR ]; then
      CMD="mkdir -pv $DEST_DIR"
      handle_dry_run $CMD
    fi
    if [ ! $DIR/$D -ef $DEST/$D ]; then # if they're not the same suggest linking
      if [ -d $DEST/$D ]; then
        CMD="mv -T --backup=numbered $DEST/$D $DEST/$D~ && ln -sv -T $DIR/$D $DEST/$D"
        handle_dry_run $CMD
      else
        CMD="ln -sv --backup=numbered -T $DIR/$D $DEST/$D"
        handle_dry_run $CMD
      fi
    fi
  done
}

for P in $PROGS_TO_CHECK; do
  check_program $P
done

#! /bin/bash

# stolen from http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in 
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEST="$HOME"
BACKUP_DIR="/tmp/backup/`date +%s0`"

mkdir -p $DEST
mkdir -p $BACKUP_DIR
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
git"

function check_program {
  which $1 > /dev/null
  if [ $? -ne 0 ]; then
    echo sudo $PACK_MGR -y install $1
  else
    remind_to_install_config_files $1
  fi
}

function remind_to_install_config_files {
  case "$1" in
    bash)
      CONFIG_DIRS=".bashrc
.bash_aliases"
      ;;
    vim)
      echo "Making sure submodules loaded"
      git submodule init
      git submodule update
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
        echo "sign into the https://console.aws.amazon.com/s3/home to get S3 access keys"
      fi
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
      echo "CONSIDER DELETING $D FROM CONFIG FILES!!!!!!!"
      exit 1
    fi
    DEST_DIR=`dirname $DEST/$D`
    if [ ! -e $DEST_DIR ]; then
      echo mkdir -pv $DEST_DIR
    fi
    if [ $D -ef $DEST/$D ]; then
      echo ln -sv --backup=numbered -T "$D" "$DEST/$D"
    fi
  done
}

for P in $PROGS_TO_CHECK; do
  check_program $P
done


#FILES=`find . -type f -wholename "./.*" | sed -e 's/^\.\///' | grep -vE "^.git(/|modules|ignore)"`
#for FILE in $FILES; do
#  RELATIVE_DIR=`dirname $FILE`
#  DESTINATION="$DEST/$RELATIVE_DIR"
#  mkdir -pv $DESTINATION
#  ln -sv --backup=numbered "$DIR/$FILE" $DESTINATION/
#done

#! /bin/bash

# stolen from http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in 
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEST="$HOME"
BACKUP_DIR="/tmp/backup/`date +%s0`"

mkdir -p $DEST
mkdir -p $BACKUP_DIR
cd $DIR

FILES=`find . -type f -wholename "./.*" | sed -e 's/^\.\///' | grep -vE "^.git(/|modules|ignore)"`
for FILE in $FILES; do
  RELATIVE_DIR=`dirname $FILE`
  DESTINATION="$DEST/$RELATIVE_DIR"
  mkdir -pv $DESTINATION
  ln -sv --backup=numbered "$DIR/$FILE" $DESTINATION/
done

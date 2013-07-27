#! /bin/bash

# stolen from http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in 
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEST="$HOME"
BACKUP_DIR="/tmp/backup/`date +%s0`"
PLineSymbolsURL="https://github.com/Lokaltog/powerline/raw/develop/font/PowerlineSymbols.otf"
PLineSymbols="`basename $PLineSymbolsURL`"
PLineConfURL="https://github.com/Lokaltog/powerline/raw/develop/font/10-powerline-symbols.conf"
PLineConf="`basename $PLineConfURL`"
TempDir="/tmp/powerline-fonts"
PLineFontPrefix="UbuntuMono/Ubuntu"

URLS="$PLineSymbolsURL $PLineConfURL"

mkdir -p $DEST
mkdir -p $BACKUP_DIR
cd $DIR

echo "Getting Powerline Fontconfig files"
for URL in $URLS; do
  FILE="`basename $URL`"
  echo "$URL being saved to $FILE"
  curl -Lso /tmp/$FILE $URL
done

echo "Creating Font directories"
FONTDIRS=".fonts.conf.d .config/fontconfig/conf.d .fonts" #.fonts must be last
for FONTDIR in $FONTDIRS; do
  mkdir -vp $DEST/$FONTDIR
done

echo "Moving fonts into place"
FONTDIR="$DEST/$FONTDIR"
mv -v /tmp/$PLineSymbols $FONTDIR
cp -v /tmp/$PLineConf $DEST/.fonts.conf.d
mv -v /tmp/$PLineConf $DEST/.fontconfig/conf.d

echo "Caching new font"
fc-cache -vf $FONTDIR

fc-list | grep -i "powerline" || exit

echo "==================="
echo "Getting pre-patched fonts from github"
rm -rf $TempDir
git clone https://github.com/Lokaltog/powerline-fonts.git $TempDir

echo "Moving and Caching pre-patched font"
mv -v $TempDir/$PLineFontPrefix*ttf $FONTDIR
fc-cache -vf $FONTDIR

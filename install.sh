#!/bin/bash

CSGOPATH="${HOME}/.steam/steam/steamapps/common/Counter-Strike Global Offensive/csgo"

TEMP=$(mktemp -d)
RARFILE=stuff.rar
ZIPFILE=stuff.zip

echo $TEMP
pushd $TEMP

curl "https://files.gamebanana.com/gamefiles/csgo_textmodorel_3.rar" > $RARFILE
unrar e $RARFILE
rm $RARFILE
mv "csgo_textmodorel.txt" "$CSGOPATH/resource/csgo_textmod.txt"


curl "http://simpleradar.com/downloads/fullpackV2.zip" > $ZIPFILE
unzip $ZIPFILE
rm $ZIPFILE
mv *.dds "$CSGOPATH/resource/overviews/"
rm "$CSGOPATH/resource/overviews/de_cache_radar_spectate.dds" 2> /dev/null

popd

cp -r src/* "$CSGOPATH/cfg/"

rm -rf $TEMP

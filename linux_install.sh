#!/bin/bash

VERSION=1.07
STEAM_COMMON=~/.steam/steam/steamapps/common/
SBDF9_BACKUP=~/.local/share/doublefine/spacebasedf9/Saves/

if [ "$1" = "restore" ]; then
    if [ ! -d ${STEAM_COMMON}/SpacebaseDF9.v1 ]; then
	echo "Missing original version of game to be restored"
	echo "Try manually re-installing through Steam"
    else
	rm -rf ${STEAM_COMMON}/SpacebaseDF9
	mv ${STEAM_COMMON}/SpacebaseDF9.v1 ${STEAM_COMMON}/SpacebaseDF9
    fi
    exit
elif [ $1 = "dist" ]; then
    prefix=spacebase-df9-v${VERSION}
    git archive --format=tar HEAD --prefix=${prefix}/ | bzip2 >${prefix}.tar.bz
    ls -l spacebase-df9-v${VERSION}.tar.bz
    exit
fi

## Backup if needed
if [ ! -e ${STEAM_COMMON}/SpacebaseDF9.v1 ]; then
    echo "Backing up original SpacebaseDF9 code and game save"
    rsync -avz ${STEAM_COMMON}/SpacebaseDF9/ ${STEAM_COMMON}/SpacebaseDF9.v1
fi
if [ ! -e ${SBDF9_BACKUP}/Archives/SpacebaseDF9AutoSave-v1.sav ]; then
    mkdir -p ${SBDF9_BACKUP}/Archives
    rsync -avz ${SBDF9_BACKUP}/SpacebaseDF9AutoSave.sav ${SBDF9_BACKUP}/Archives/SpacebaseDF9AutoSave-v1.sav 
fi

rsync -avz Data/* ${STEAM_COMMON}/SpacebaseDF9/Data/

# Treat Win directory as authoritative for graphics
rsync -avz Win/* ${STEAM_COMMON}/SpacebaseDF9/Linux/


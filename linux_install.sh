#!/bin/bash

STEAM_COMMON=~/.steam/steam/steamapps/common/
SBDF9_BACKUP=~/.local/share/doublefine/spacebasedf9/Saves/

## Backup if needed
if [ ! -e ${STEAM_COMMON}/SpacebaseDF9.v1 ]; then
    echo "Backing up original SpacebaseDF9 code and game save"
    rsync -avz ${STEAM_COMMON}/SpacebaseDF9 ${STEAM_COMMON}/SpacebaseDF9.v1
    rsync -avz ${SBDF9_BACKUP}/SpacebaseDF9AutoSave.sav ${SBDF9_BACKUP}/SpacebaseDF9AutoSave-v1.sav 
fi

rsync -avz Dialog ${STEAM_COMMON}/SpacebaseDF9/
rsync -avz Scripts ${STEAM_COMMON}/SpacebaseDF9/
rsync -avz UILayouts ${STEAM_COMMON}/SpacebaseDF9/



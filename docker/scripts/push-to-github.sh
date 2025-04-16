#!/bin/bash

# This script is used to push the home assistant config files to github
mkdir -p /opt/home-assistant-config/$MACHINE_NICKNAME
cd /opt/home-assistant-config
git pull
cp /homeassistant/*.yaml ./$MACHINE_NICKNAME/
cp /homeassistant/esphome ./$MACHINE_NICKNAME/

if [[ -n $(git status --porcelain) ]]; then
    git add .
    git commit -m "automatic commit from $MACHINE_NICKNAME"
    git push origin main
    echo "`date +%Y%m%d_%H%M%S%Z`: git push completed"
else
    echo "`date +%Y%m%d_%H%M%S%Z`: No changes found."
fi

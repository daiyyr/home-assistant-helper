#!/bin/bash

# This script is used to push the home assistant config files to github
MachineNickName=`cat /homeassistant/machine_nickname.txt`
mkdir -p /homeassistant/home-assistant-config/$MachineNickName
cd /homeassistant/home-assistant-config
git pull
cp ../*.yaml ./$MachineNickName/
cp ../esphome ./$MachineNickName/

if [[ -n $(git status --porcelain) ]]; then
    git add .
    git commit -m "automatic commit from $MachineNickName"
    git push origin main
    echo "`date +%Y%m%d_%H%M%S%Z`: git push completed"
else
    echo "`date +%Y%m%d_%H%M%S%Z`: No changes found."
fi

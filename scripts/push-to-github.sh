#!/bin/bash

# This script is used to push the home assistant config files to github
MACHINE_NICKNAME=`cat /opt/machine_nickname.txt`
GITHUB_TOKEN=$(aws ssm get-parameter --name /github/pat/home-assistant-config --with-decryption --query 'Parameter.Value' --output text --region="ap-southeast-2")

cd /opt

if [ ! -d "/opt/home-assistant-config" ]; then
    git clone https://${MACHINE_NICKNAME}:${GITHUB_TOKEN}@github.com/daiyyr/home-assistant-config
fi

mkdir -p /opt/home-assistant-config/$MACHINE_NICKNAME
cd /opt/home-assistant-config
git pull

cp /homeassistant/*.yaml ./$MACHINE_NICKNAME/
cp -R /homeassistant/esphome ./$MACHINE_NICKNAME/
# maybe add more folder here in the future


if [[ -n $(git status --porcelain) ]]; then
    git add .
    git commit -m "automatic commit from $MACHINE_NICKNAME"
    git push origin main
    echo "`date +%Y%m%d_%H%M%S%Z`: git push completed"
fi

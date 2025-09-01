#!/bin/bash

set -euo pipefail
# Drop stdout globally; keep stderr for errors
exec 1>/dev/null

# This script is used to push the home assistant config files to github
MACHINE_NICKNAME=`cat /opt/machine_nickname.txt`
GITHUB_TOKEN=$(aws ssm get-parameter --name /github/pat/home-assistant-config --with-decryption --query 'Parameter.Value' --output text --region="ap-southeast-2")

cd /opt

if [ ! -d "/opt/home-assistant-config" ]; then
    git clone https://${MACHINE_NICKNAME}:${GITHUB_TOKEN}@github.com/daiyyr/home-assistant-config
fi

mkdir -p /opt/home-assistant-config/$MACHINE_NICKNAME/.storage/

# Quiet pull (no “Already up to date.” spam)
git -C /opt/home-assistant-config pull --quiet


cp /homeassistant/*.yaml /opt/home-assistant-config/$MACHINE_NICKNAME/
cp -R /homeassistant/esphome /opt/home-assistant-config/$MACHINE_NICKNAME/
cp /homeassistant/.storage/lovelace* /opt/home-assistant-config/$MACHINE_NICKNAME/.storage/ # dashboards config
# maybe add more folder here in the future


if [[ -n $(git -C /opt/home-assistant-config status --porcelain) ]]; then
    git -C /opt/home-assistant-config add -A
    git -C /opt/home-assistant-config commit --quiet -m "automatic commit from $MACHINE_NICKNAME"
    git -C /opt/home-assistant-config push --quiet origin main
fi

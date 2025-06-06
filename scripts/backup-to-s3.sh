#!/bin/bash
# This script is used to upload the home assistant backup files to an S3 bucket
MACHINE_NICKNAME=`cat /opt/machine_nickname.txt`
aws s3 sync /backup s3://the-alchemist-home-assistant/$MACHINE_NICKNAME/backup/  --delete
echo echo "`date +%Y%m%d_%H%M%S%Z`: s3 sync completed"

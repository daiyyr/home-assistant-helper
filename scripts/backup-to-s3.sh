#!/bin/bash
# This script is used to upload the home assistant backup files to an S3 bucket

MACHINE_NICKNAME=`cat /opt/machine_nickname.txt`
aws s3 sync /backup s3://the-alchemist-home-assistant/$MACHINE_NICKNAME/backup/  --delete --no-progress --only-show-errors

# timestamp when an error occurs:
if [ $? -ne 0 ]; then
    echo "$(date +%Y%m%d_%H%M%S%Z): s3 sync failed" >&2
fi

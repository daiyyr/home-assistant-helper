#!/bin/bash
# This script is used to upload the home assistant backup files to an S3 bucket

aws s3 sync /backup s3://the-alchemist-home-assistant/home/backup/  --delete
echo "s3 sync completed"

#!/bin/bash

# Load machine nickname
MACHINE_NICKNAME=$(cat /opt/machine_nickname.txt)

# Create timestamp
TIMESTAMP=$(date +%Y%m%d)

# Define paths
ZIP_FILE="/media/reolink_${TIMESTAMP}.zip"
REOLINK_DIR="/media/reolink"

# Zip the /media/reolink folder contents (without including the top-level folder itself)
cd "$REOLINK_DIR"
zip -r "$ZIP_FILE" ./*

# Upload the zip to S3
aws s3 cp "$ZIP_FILE" s3://the-alchemist-home-assistant/$MACHINE_NICKNAME/media/reolink_${TIMESTAMP}.zip

# Remove all files and subfolders inside /media/reolink but keep the folder itself
rm -rf "$REOLINK_DIR"/* "$REOLINK_DIR"/.??*
rm -rf "$ZIP_FILE"

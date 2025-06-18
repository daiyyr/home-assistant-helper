#!/bin/bash

MACHINE_NICKNAME=$(cat /opt/machine_nickname.txt)
WATCH_DIR="/opt/reolink"

inotifywait -m -r -e close_write,moved_to,create "$WATCH_DIR" --format '%w%f' | while read NEWFILE
do
    if [ -f "$NEWFILE" ]; then
        REL_PATH="${NEWFILE#$WATCH_DIR/}"
        S3_PATH="s3://the-alchemist-home-assistant/$MACHINE_NICKNAME/reolink/$REL_PATH"
        # echo "$(date +%Y%m%d_%H%M%S): Detected file $NEWFILE, uploading to $S3_PATH"
        
        if aws s3 cp "$NEWFILE" "$S3_PATH"; then
            # echo "$(date +%Y%m%d_%H%M%S): Upload successful, deleting $NEWFILE"
            rm -f "$NEWFILE"
        else
            echo "$(date +%Y%m%d_%H%M%S): Upload failed, keeping $NEWFILE"
        fi
    fi
done

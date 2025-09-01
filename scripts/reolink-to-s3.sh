#!/bin/bash

MACHINE_NICKNAME=$(cat /opt/machine_nickname.txt)
WATCH_DIRS=("/media/reolink" "/media/reolink_front")
BUCKET="s3://the-alchemist-home-assistant"

inotifywait -m -r -e close_write,moved_to,create --format '%w%f' "${WATCH_DIRS[@]}" | while read -r NEWFILE
do
    if [ -f "$NEWFILE" ]; then
        # if the file ends with .jpg, remove it
        if [[ $NEWFILE =~ \.jpg$ ]]; then
            rm -f "$NEWFILE"
            continue
        fi

        # find which watched dir this file came from
        BASE_WATCH_DIR=""
        for WD in "${WATCH_DIRS[@]}"; do
            case "$NEWFILE" in
                "$WD"/*) BASE_WATCH_DIR="$WD"; break ;;
            esac
        done
        if [ -z "$BASE_WATCH_DIR" ]; then
            echo "$(date +%Y%m%d_%H%M%S): Skipping $NEWFILE (not under watched dirs?)"
            continue
        fi

        REL_PATH="${NEWFILE#$BASE_WATCH_DIR/}"       # path under the matched watch dir
        WATCH_NAME="$(basename -- "$BASE_WATCH_DIR")" # e.g. reolink, reolink_frontdoor, reolink_garden
        FILENAME="$(basename -- "$NEWFILE")"    # e.g. clip_001.mp4
        ZIP_PATH="/tmp/${REL_PATH}.zip" # e.g. /tmp/clip_001.mp4.zip
        S3_BASE="s3://the-alchemist-home-assistant/$MACHINE_NICKNAME/reolink/$REL_PATH"
        S3_ZIP_PATH="${BUCKET}/${MACHINE_NICKNAME}/${WATCH_NAME}/${REL_PATH}.zip"
        
        # start fresh so zip doesn't update/append
        rm -f -- "$ZIP_PATH"
        
        # create the zip (store just the file inside the ZIP)
        if zip -j -q -- "$ZIP_PATH" "$NEWFILE"; then
            if aws s3 cp -- "$ZIP_PATH" "$S3_ZIP_PATH"; then
                # on success, remove both the original and the zip
                rm -f -- "$NEWFILE" "$ZIP_PATH"
            else
                echo "$(date +%Y%m%d_%H%M%S): Upload failed for $ZIP_PATH -> $S3_ZIP_PATH, keeping files"
            fi
        else
            echo "$(date +%Y%m%d_%H%M%S): Zip failed for $NEWFILE"
        fi
    fi
done

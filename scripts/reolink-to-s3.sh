#!/bin/bash

MACHINE_NICKNAME=$(cat /opt/machine_nickname.txt)
WATCH_DIRS=("/media/reolink" "/media/reolink_front")
BUCKET="s3://the-alchemist-home-assistant"

# wait until file size is stable and > 0 (max ~60s)
wait_for_complete() {
  local f="$1"
  local max_tries=60
  local s1 s2
  for ((i=0; i<max_tries; i++)); do
    [[ -f "$f" ]] || return 1
    # portable stat for Linux/macOS
    if s1=$(stat -c%s "$f" 2>/dev/null); then :; else s1=$(stat -f%z "$f" 2>/dev/null || echo 0); fi
    sleep 1
    if s2=$(stat -c%s "$f" 2>/dev/null); then :; else s2=$(stat -f%z "$f" 2>/dev/null || echo 0); fi
    if [[ "$s1" -gt 0 && "$s1" -eq "$s2" ]]; then
      return 0
    fi
  done
  return 1
}

inotifywait -m -r -e close_write,moved_to,create --format '%w%f' "${WATCH_DIRS[@]}" | while read -r NEWFILE
do
    if [ -f "$NEWFILE" ]; then
        # if the file ends with .jpg, remove it
        if [[ $NEWFILE =~ \.jpg$ ]]; then
            rm -f "$NEWFILE"
            continue
        fi

        # make sure we're not racing the writer (esp. on network shares)
        if ! wait_for_complete "$NEWFILE"; then
            echo "$(date +%Y%m%d_%H%M%S): Timed out waiting for $NEWFILE to finish, skipping"
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
        TEMP_FILE="/tmp/${FILENAME}"
        ZIP_PATH="${TEMP_FILE}.zip" # e.g. /tmp/clip_001.mp4.zip
        S3_ZIP_PATH="${BUCKET}/${MACHINE_NICKNAME}/${WATCH_NAME}/${REL_PATH}.zip"
        
        # start fresh so zip doesn't update/append
        rm -f -- "$ZIP_PATH"
        
        # create the zip (store just the file inside the ZIP)
        mv "$NEWFILE" "$TEMP_FILE"
        if zip -j -q "$ZIP_PATH" "$TEMP_FILE"; then
            sync "$ZIP_PATH"
            if aws s3 mv --no-progress --only-show-errors -- "$ZIP_PATH" "$S3_ZIP_PATH"; then
                # on success, remove TEMP_FILE
                # rm -f -- "$TEMP_FILE"
                echo "succeed"
            else
                echo "$(date +%Y%m%d_%H%M%S): Upload failed for $ZIP_PATH -> $S3_ZIP_PATH, keeping files"
            fi
        else
            echo "$(date +%Y%m%d_%H%M%S): Zip failed for $NEWFILE"
        fi
    fi
done

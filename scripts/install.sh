
#!/bin/bash

# Exit on error
set -e

# Ensure a machine nickname is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <MACHINE_NICKNAME>"
  exit 1
fi

MACHINE_NICKNAME="$1"
DOMEAIN_NAME="the-alchemist.link"

# Install required packages. 
# Depending on the OS, you may need to use the relevant package manager to install the AWS CLI. Home Assistant Operating System for Raspberry Pi is based on Alpine Linux, so we use apk here
apk add git cronie openrc aws-cli curl certbot certbot-dns-route53 inotify-tools

# Configure AWS CLI
# You will be prompted to enter AWS Access Key ID, Secret Access Key, and region
if [ ! -f "/root/.aws/credentials" ] || ! grep -q "aws_access_key_id" /root/.aws/credentials; then
    aws configure
fi

# Set up git and machine nickname
echo "$MACHINE_NICKNAME" > /opt/machine_nickname.txt
git config --global user.name "$MACHINE_NICKNAME"
git config --global user.email "$MACHINE_NICKNAME@$DOMEAIN_NAME"


# Create certificate
if [ ! -f "/config/ssl/fullchain.pem" ]; then
    certbot certonly --dns-route53 -d $MACHINE_NICKNAME.$DOMEAIN_NAME --non-interactive --agree-tos --register-unsafely-without-email
    cp /etc/letsencrypt/live/$MACHINE_NICKNAME.$DOMEAIN_NAME/fullchain.pem /config/ssl/fullchain.pem
    cp /etc/letsencrypt/live/$MACHINE_NICKNAME.$DOMEAIN_NAME/privkey.pem /config/ssl/privkey.pem
    chmod 644 /config/ssl/fullchain.pem
    chmod 644 /config/ssl/privkey.pem
fi


# Clone the helper repo
cd /opt
rm -rf /opt/home-assistant-helper
git clone https://github.com/daiyyr/home-assistant-helper


# Prepare directory
mkdir -p /root/.cache
mkdir -p /media/reolink
mkdir -p /media/reolink_front


# start reolink-to-s3.sh
TARGET="/opt/home-assistant-helper/scripts/reolink-to-s3.sh"
LOG="/var/log/reolink-watch.log"
# Stop existing instance(s)
PIDS=$(pgrep -f "$TARGET" || true)
if [ -n "$PIDS" ]; then
  echo "Stopping old instance(s)..."
  for PID in $PIDS; do
    pkill -TERM -P $PID || true
    sleep 1
    pkill -KILL -P $PID || true
  done
  # clean up any straggler inotifywait processes
  pkill -TERM -f inotifywait || true
  sleep 1
  pkill -KILL -f inotifywait || true
fi
# Start fresh
echo "Starting: $TARGET"
"$TARGET" >> "$LOG" 2>&1 &
echo "PID: $!"



# Add cron jobs
if ! grep -q "update-dns.sh" /etc/crontabs/root; then
    echo "*/5 * * * * /opt/home-assistant-helper/scripts/update-dns.sh >> /var/log/update-dns.log 2>&1" >> /etc/crontabs/root
fi
if ! grep -q "backup-to-s3.sh" /etc/crontabs/root; then
    echo "0 3 * * 0 /opt/home-assistant-helper/scripts/backup-to-s3.sh >> /var/log/s3-backup.log 2>&1" >> /etc/crontabs/root
fi
if ! grep -q "push-to-github.sh" /etc/crontabs/root; then
    echo "*/3 * * * * /opt/home-assistant-helper/scripts/push-to-github.sh >> /var/log/github-backup.log 2>&1" >> /etc/crontabs/root
fi
if ! grep -q "certbot" /etc/crontabs/root; then
    echo "0 2 1 * * /opt/home-assistant-helper/scripts/update-cert.sh \"$MACHINE_NICKNAME\"" >> /etc/crontabs/root
fi

# Start cron daemon
if ! pgrep -x "crond" > /dev/null; then
    crond
fi

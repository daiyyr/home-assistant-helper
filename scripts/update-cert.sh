#!/bin/sh

# Exit on error
set -e

# Ensure a machine nickname is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <MACHINE_NICKNAME>"
  exit 1
fi

MACHINE_NICKNAME="$1"
DOMEAIN_NAME="the-alchemist.link"
R53HostedZoneId_for_mail="Z0418706D4R5AHFWGBQ9"

certbot renew --quiet

if [ ! -f "/etc/letsencrypt/live/$MACHINE_NICKNAME.$DOMEAIN_NAME/fullchain.pem" ]; then
    certbot certonly --dns-route53 -d $MACHINE_NICKNAME.$DOMEAIN_NAME --non-interactive --agree-tos --register-unsafely-without-email
fi

cp /etc/letsencrypt/live/$MACHINE_NICKNAME.$DOMEAIN_NAME/fullchain.pem /config/ssl/fullchain.pem
cp /etc/letsencrypt/live/$MACHINE_NICKNAME.$DOMEAIN_NAME/privkey.pem /config/ssl/privkey.pem
chmod 644 /config/ssl/fullchain.pem
chmod 644 /config/ssl/privkey.pem

# Update mail certificate if this is the main home machine
if [ "$MACHINE_NICKNAME" == "home" ]; then
    MAIL_DOMAIN=`aws route53 get-hosted-zone --id ${R53HostedZoneId_for_mail} --query "HostedZone.Name" --output text`
    MAIL_DOMAIN=${MAIL_DOMAIN%.}
    MAIL_DOMAIN_NAME=mail.$MAIL_DOMAIN
    if [ ! -f "/etc/letsencrypt/live/$MAIL_DOMAIN_NAME/fullchain.pem" ]; then
        certbot certonly --dns-route53 -d $MAIL_DOMAIN_NAME --non-interactive --agree-tos --register-unsafely-without-email
    fi
fi

# ha core restart

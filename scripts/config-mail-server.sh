#!/bin/sh
set -e

R53HostedZoneId_for_mail="Z0418706D4R5AHFWGBQ9"
EMAIL_USER="teemo"

# === CONFIGURATION ===

MACHINE_NICKNAME=`cat /opt/machine_nickname.txt`
DOMAIN=`aws route53 get-hosted-zone --id ${R53HostedZoneId_for_mail} --query "HostedZone.Name" --output text`
DOMAIN=${DOMAIN%.}
MAIL_DOMAIN="mail.$DOMAIN"

echo "=== Updating system ==="
apk update && apk upgrade

echo "=== Installing packages ==="
apk add --no-cache postfix dovecot openssl certbot shadow

echo "=== Create /etc/dovecot dir if missing ==="
mkdir -p /etc/dovecot

# === Obtain TLS certificate if missing ===
if [ ! -f "/etc/letsencrypt/live/$MAIL_DOMAIN/fullchain.pem" ]; then
    echo "=== Stopping mail services to get cert ==="
    rc-service postfix stop 2>/dev/null || true
    rc-service dovecot stop 2>/dev/null || true
fi

# === Configure Postfix ===
postconf -e "myhostname = $MAIL_DOMAIN"
postconf -e "mydomain = $DOMAIN"
postconf -e "myorigin = /etc/mailname"
postconf -e "inet_interfaces = all"
postconf -e "inet_protocols = ipv4"
postconf -e "home_mailbox = Maildir/"
postconf -e "smtpd_tls_cert_file = /etc/letsencrypt/live/$MAIL_DOMAIN/fullchain.pem"
postconf -e "smtpd_tls_key_file = /etc/letsencrypt/live/$MAIL_DOMAIN/privkey.pem"
postconf -e "smtpd_tls_security_level = may"
postconf -e "smtp_tls_security_level = may"
postconf -e "smtpd_tls_auth_only = yes"
postconf -e "smtpd_tls_protocols = !SSLv2,!SSLv3"
postconf -e "smtpd_tls_loglevel = 1"

# === Configure Dovecot ===
cat >/etc/dovecot/dovecot.conf <<EOF
# Start new configs with the latest Dovecot version numbers here:
dovecot_config_version = 2.4.0
dovecot_storage_version = 2.4.0

# Enable wanted protocols:
protocols {
  imap = yes
}

mail_home = /home/$EMAIL_USER
mail_driver = sdbox
mail_path = ~/mail

mail_uid = $EMAIL_USER
mail_gid = $EMAIL_USER

# By default first_valid_uid is 500. If your $EMAIL_USER user's UID is smaller,
# you need to modify this:
#first_valid_uid = uid-number-of-vmail-user

namespace inbox {
  inbox = yes
  separator = /
}

# Authenticate as system users:
passdb pam {
}

ssl_cert = </etc/letsencrypt/live/$MAIL_DOMAIN/fullchain.pem
ssl_key = </etc/letsencrypt/live/$MAIL_DOMAIN/privkey.pem
EOF

# === Create mail user if missing ===
if ! id "$EMAIL_USER" >/dev/null 2>&1; then
    adduser -D "$EMAIL_USER"
    # Set password interactively
    echo "=== Set password for $EMAIL_USER ==="
    passwd "$EMAIL_USER"
fi

# Create Maildir if missing
mkdir -p /home/$EMAIL_USER/Maildir
chown -R $EMAIL_USER:$EMAIL_USER /home/$EMAIL_USER/Maildir

# === Start Postfix (still OpenRC optional) ===
if ! pgrep postfix >/dev/null 2>&1; then
    /usr/sbin/postfix start
fi

# === Start Dovecot manually if not running ===
if ! pgrep dovecot >/dev/null 2>&1; then
    echo "Starting Dovecot in foreground ..."
    dovecot -F -c /etc/dovecot/dovecot.conf >> /var/log/dovecot.log 2>&1 &
fi
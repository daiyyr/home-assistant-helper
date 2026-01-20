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
postconf -e "smtpd_use_tls = yes"
postconf -e "smtpd_tls_security_level = may"
postconf -e "smtp_tls_security_level = may"
postconf -e "smtpd_tls_auth_only = yes"
postconf -e "smtpd_tls_protocols = !SSLv2,!SSLv3"
postconf -e "smtpd_tls_loglevel = 1"

# === Configure Dovecot ===
cat >/etc/dovecot/dovecot.conf <<EOF
# Dovecot main configuration
dovecot_config_version = 2.4
# Networking
listen = *
protocols = imap pop3
# Authentication
disable_plaintext_auth = yes
auth_mechanisms = plain login
# Mail storage
mail_location = maildir:~/Maildir
# SSL/TLS
ssl = required
ssl_cert = </etc/letsencrypt/live/$MAIL_DOMAIN/fullchain.pem
ssl_key = </etc/letsencrypt/live/$MAIL_DOMAIN/privkey.pem
ssl_min_protocol = TLSv1.2
ssl_prefer_server_ciphers = yes
# Privileges
mail_privileged_group = mail
# Logging (optional but recommended for debugging)
log_path = /var/log/dovecot.log
info_log_path = /var/log/dovecot-info.log
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

# === Restart services, ignore errors if already running ===
rc-service postfix restart 2>/dev/null || true
rc-service dovecot restart 2>/dev/null || true

echo "======================================"
echo " Mail server setup complete!"
echo " Email: $EMAIL_USER@$DOMAIN"
echo " IMAP: $MAIL_DOMAIN : 993 (SSL)"
echo " SMTP: $MAIL_DOMAIN : 587 (STARTTLS)"
echo "======================================"
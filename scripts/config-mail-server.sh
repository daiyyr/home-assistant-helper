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
apk add postfix dovecot dovecot-pop3d dovecot-imapd openssl certbot shadow

# === Obtain TLS certificate ===
echo "=== Stopping mail services to get cert ==="
rc-service postfix stop || true
rc-service dovecot stop || true

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
disable_plaintext_auth = yes
mail_privileged_group = mail
EOF

cat >/etc/dovecot/conf.d/10-mail.conf <<EOF
mail_location = maildir:~/Maildir
EOF

cat >/etc/dovecot/conf.d/10-auth.conf <<EOF
auth_mechanisms = plain login
!include auth-system.conf.ext
EOF

cat >/etc/dovecot/conf.d/10-ssl.conf <<EOF
ssl = required
ssl_cert = </etc/letsencrypt/live/$MAIL_DOMAIN/fullchain.pem
ssl_key = </etc/letsencrypt/live/$MAIL_DOMAIN/privkey.pem
EOF

# === Create email user ===
if ! id "$EMAIL_USER" >/dev/null 2>&1; then
  adduser -D "$EMAIL_USER"
fi

# Set password interactively
echo "=== Set password for $EMAIL_USER ==="
passwd "$EMAIL_USER"

# Create Maildir
mkdir -p /home/$EMAIL_USER/Maildir
chown -R $EMAIL_USER:$EMAIL_USER /home/$EMAIL_USER/Maildir

# === Start services ===
rc-service postfix restart
rc-service dovecot restart

echo "======================================"
echo " Mail server setup complete!"
echo " Email: $EMAIL_USER@$DOMAIN"
echo " IMAP: $MAIL_DOMAIN : 993 (SSL)"
echo " SMTP: $MAIL_DOMAIN : 587 (STARTTLS)"
echo "======================================"

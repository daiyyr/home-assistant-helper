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
apk add --no-cache postfix dovecot openssl certbot shadow dovecot-lmtpd

echo "=== Create /etc/dovecot dir if missing ==="
mkdir -p /etc/dovecot

# === Configure Postfix ===
postconf -e "mynetworks_style = host"
postconf -e "relay_domains = $DOMAIN"
postconf -e "myhostname = $MAIL_DOMAIN"
postconf -e "mydomain = $DOMAIN"
postconf -e "myorigin = $DOMAIN"
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
postconf -e "smtpd_sasl_auth_enable = yes"
postconf -e "smtpd_sasl_type = dovecot"
postconf -e "smtpd_sasl_path = private/auth"
postconf -e "virtual_transport = lmtp:unix:private/dovecot-lmtp"


BLOCK_MARKER="## Gmail submission block"

# Check if block already exists
if ! grep -q "$BLOCK_MARKER" /etc/postfix/master.cf; then
  echo "$BLOCK_MARKER" | sudo tee -a /etc/postfix/master.cf
  sudo tee -a /etc/postfix/master.cf > /dev/null <<'EOF'
submission inet n       -       n       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_tls_auth_only=yes
  -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
EOF
fi


# === Configure Dovecot ===
cat >/etc/dovecot/dovecot.conf <<EOF
# Start new configs with the latest Dovecot version numbers here:
dovecot_config_version = 2.4.0
dovecot_storage_version = 2.4.0

# Enable wanted protocols:
protocols {
  imap = yes
  lmtp = yes
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

ssl_server_cert_file = /etc/letsencrypt/live/$MAIL_DOMAIN/fullchain.pem
ssl_server_key_file = /etc/letsencrypt/live/$MAIL_DOMAIN/privkey.pem

service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    mode = 0600
    group = postfix
    user = postfix
  }
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    group = postfix
    user = postfix
  }
}

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
if ! pgrep -x master >/dev/null 2>&1; then
    /usr/sbin/postfix start
fi

# === Start Dovecot manually if not running ===
if ! pgrep dovecot >/dev/null 2>&1; then
    echo "Starting Dovecot in foreground ..."
    dovecot -F -c /etc/dovecot/dovecot.conf >> /var/log/dovecot.log 2>&1 &
fi

# test
# openssl s_client -connect localhost:993

doveadm pw -s PLAIN -u $EMAIL_USER@$DOMAIN

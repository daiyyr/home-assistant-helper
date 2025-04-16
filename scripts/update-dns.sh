#!/bin/bash
MACHINE_NICKNAME=`cat /opt/machine_nickname.txt`
R53HostedZoneId="Z06958611JDYVCG41K93R"

IP_FILE="/opt/previous-ip.txt"
mkdir -p "$(dirname "$IP_FILE")"

# Read the previous IP from the file
if [ -f "$IP_FILE" ]; then
  PREVIOUS_IP=$(cat "$IP_FILE")
else
  PREVIOUS_IP=""
fi

# Fetch the public IP
PUBLIC_IP=$(curl -s https://checkip.amazonaws.com)

if [ "$PUBLIC_IP" != "$PREVIOUS_IP" ]; then
  echo "`date +%Y%m%d_%H%M%S%Z` Public IP has changed to $PUBLIC_IP. Updating Route 53 record..."
    
    # if R53HostedZoneId exists, update Route 53 record
    if [ -z "$R53HostedZoneId" ]; then
        echo "R53HostedZoneId is unset"
    else
        DOMAIN_NAME=`aws route53 get-hosted-zone --id ${R53HostedZoneId} --query 'HostedZone.Name' --output text | sed 's/.$//'`
        URL=${MACHINE_NICKNAME}.$DOMAIN_NAME
        aws route53 change-resource-record-sets --hosted-zone-id ${R53HostedZoneId} --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'"$URL"'","Type":"A","TTL":10,"ResourceRecords":[{"Value":"'"$PUBLIC_IP"'"}]}}]}'
    fi

  # Save the new IP for future comparisons
  echo $PUBLIC_IP > "$IP_FILE"

# else
#   echo "`date +%Y%m%d_%H%M%S%Z`: ip not changed"
fi

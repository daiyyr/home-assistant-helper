#!/bin/bash

# update MachineNickName for each machine
R53HostedZoneId="Z06958611JDYVCG41K93R"
MachineNickName="home"

IP_FILE="/homeassistant/granular-dynamic-dns/previous-ip.txt"
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
  echo "Public IP has changed. Updating Route 53 record..."
    
    # if R53HostedZoneId exists, update Route 53 record
    if [ -z "$R53HostedZoneId" ]; then
        echo "R53HostedZoneId is unset"
    else
        DOMAIN_NAME=`aws route53 get-hosted-zone --id ${R53HostedZoneId} --query 'HostedZone.Name' --output text | sed 's/.$//'`
        URL=${MachineNickName}.$DOMAIN_NAME
        aws route53 change-resource-record-sets --hosted-zone-id ${R53HostedZoneId} --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'"$URL"'","Type":"A","TTL":10,"ResourceRecords":[{"Value":"'"$PUBLIC_IP"'"}]}}]}'
    fi

  # Save the new IP for future comparisons
  echo $PUBLIC_IP > "$IP_FILE"

else
  echo "Public IP has not changed."
fi

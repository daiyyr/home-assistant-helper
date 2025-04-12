# Introduction
- Regularly update R53 records to point to local machine public IP. Each machine use a different AWS user which can only update a specific DNS
- Regularly upload Home Assistant backup files to s3
- Regularly push Home Assistant config yaml files to github

# New machine setup
- Update workflows/deploy-dns-updaters.yaml, add a new machine nick name to deploy.strategy.matrix.machine-name, e.g. home1,machine2,machine3,newmachine4. The Github workflow should be triggered to create a new aws user with policies to update the specific dns
- Go to aws console to get AWS Secret Access Key and AWS Access Key ID for that user
- SSH to the new machine, install aws cli and configure AWS CLI with the above AWS credentials. Depending on the OS, you may need to use the relevant package manager to install the AWS CLI. Home Assistant Operating System for Raspberry Pi is based on Alpine Linux, so we use apk:

```
machine_nickname="home" # update this value for each machine

echo "$machine_nickname" > /homeassistant/machine_nickname.txt
cd /homeassistant
clone https://github.com/daiyyr/home-assistant-helper
apk add aws-cli cronie openrc
mkdir /root/.cache
mkdir -p /homeassistant/logs
aws configure
# enter AWS Secret Access Key and AWS Access Key ID from last step

chmod 775 /homeassistant/home-assistant-helper/scripts/update-dns.sh
crontab -e
# add the below line
*/5 * * * * /homeassistant/home-assistant-helper/scripts/update-dns.sh >> /homeassistant/logs/update-dns.log 2>&1

# run crond incase it's not already running - # it should already run when we did apk add cronie openrc
crond -s
```


# Upload Home Assistant backup files to s3 at 03:00 on Sunday
```
crontab -e
# add the below line
0 3 * * 0 /homeassistant/home-assistant-helper/scripts/backup-to-s3.sh >> /homeassistant/logs/s3-backup.log 2>&1
```

# Check and push Home Assistant config yaml files to github every 3 minutes
```
git config --global credential.helper store
cd /homeassistant
git clone https://github.com/daiyyr/home-assistant-config
# enter the fine-grained PAT for this repo

crontab -e
# add the below line
*/3 * * * * /homeassistant/home-assistant-helper/scripts/push-to-github.sh >/dev/null 2>&1
```

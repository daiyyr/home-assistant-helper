# Introduction
- Regularly update R53 records to point to local machine public IP. Each machine use a different AWS user which can only update a specific DNS
- Regularly upload Home Assistant backup files to s3
- Regularly push Home Assistant config yaml files to github

# New machine setup
- Update .github/workflows/ci-pipeline.yaml, add a new machine to deploy.strategy.matrix.machine-nick-name, e.g. home,home2,machine3,new_machine4. The Github workflow will be triggered to create a new cloud formation stack with aws resources for this machine.
- Go to aws console to get AWS Secret Access Key and AWS Access Key ID from the new user home-assistant-<machine-nick-name>.
- SSH to the new machine, install aws cli and configure AWS CLI with the above AWS credentials, and then start the cron job. Depending on the OS, you may need to use the relevant package manager to install the AWS CLI. Home Assistant Operating System for Raspberry Pi is based on Alpine Linux, so we use apk. Make sure to replace $MACHINE_NICKNAME with the value you defined earlier in the first step (deploy.strategy.matrix.machine-nick-name).

```
export MACHINE_NICKNAME="home" # update this value for each machine

apk add git cronie openrc aws-cli curl
aws configure
# enter AWS Secret Access Key and AWS Access Key ID from the previous step

echo "$MACHINE_NICKNAME" > /opt/machine_nickname.txt
cd /opt
git clone https://github.com/daiyyr/home-assistant-helper
mkdir -p /root/.cache
echo "*/5 * * * * /opt/home-assistant-helper/scripts/update-dns.sh >> /var/log/update-dns.log 2>&1" >> /etc/crontabs/root
echo "0 3 * * 0 /opt/home-assistant-helper/scripts/backup-to-s3.sh >> /var/log/s3-backup.log 2>&1" >> /etc/crontabs/root
echo "*/3 * * * * /opt/home-assistant-helper/scripts/push-to-github.sh >> /var/log/github-backup.log 2>&1" >> /etc/crontabs/root
crond
```

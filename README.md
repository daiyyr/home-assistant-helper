# Introduction
- Regularly update R53 records to point to local machine public IP. Each machine use a different AWS user which can only update a specific DNS
- Regularly upload Home Assistant backup files to s3
- Regularly push Home Assistant config yaml files to github

# New machine setup
- Update workflows/ci-pipeline.yaml, add a new machine nick name to deploy.strategy.matrix.machine-nick-name, e.g. home1,machine2,machine3,newmachine4. Push the change to main branch and the Github workflow should be triggered to create two IAM users - one for the docker container, oen for the host. The workflow will then build a docker image with the docker IAM user and push the image to ECR.
- Go to aws console, generate a pair of AWS Secret Access Key and AWS Access Key ID from the docker user.
- SSH to the new machine, install aws cli and configure AWS CLI with the above AWS credentials. Depending on the OS, you may need to use the relevant package manager to install the AWS CLI. Home Assistant Operating System for Raspberry Pi is based on Alpine Linux, so we use apk:
```
apk add aws-cli
aws configure
# enter AWS Secret Access Key and AWS Access Key ID from the previous step
```
- Run the home-assistant-helper docker container. Make sure to replace $machine_nickname with the value you defined earlier in the first step (deploy.strategy.matrix.machine-nick-name).

```
machine_nickname=home
aws ecr get-login-password --region ap-southeast-2 \
| docker login --username AWS --password-stdin 654654455942.dkr.ecr.ap-southeast-2.amazonaws.com
docker run -d --pull=always --restart=unless-stopped -v ~/.aws/:/root/.aws:ro -v /homeassistant:/homeassistant:ro -v /backup:/backup:ro 654654455942.dkr.ecr.ap-southeast-2.amazonaws.com/home-assistant-helper-$machine_nickname
```




# below are old readme. need delete later

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

# Introduction
- Regularly update R53 records to point to local machine public IP. Each machine use a different AWS user which can only update a specific DNS
- Regularly upload Home Assistant backup files to s3
- Regularly push Home Assistant config yaml files to github

# New machine setup
- Update workflows/ci-pipeline.yaml, add a new machine nick name to deploy.strategy.matrix.machine-nick-name, e.g. home1,machine2,machine3,newmachine4. Push the change to main branch and the Github workflow should be triggered to create two IAM users - one for the docker container, oen for the host. The workflow will then build a docker image with the docker IAM user and push the image to ECR.
- Go to aws console, generate a pair of AWS Secret Access Key and AWS Access Key ID from the docker user.
- SSH to the new machine, install aws cli and configure AWS CLI with the above AWS credentials. Depending on the OS, you may need to use the relevant package manager to install the AWS CLI. Home Assistant Operating System for Raspberry Pi is based on Alpine Linux, so we use apk. Make sure to replace $machine_nickname with the value you defined earlier in the first step (deploy.strategy.matrix.machine-nick-name).
```
machine_nickname=home

apk add aws-cli cronie openrc
aws configure
# enter AWS Secret Access Key and AWS Access Key ID from the previous step

touch /var/log/copy-files.log
echo "#!/bin/sh" > /tmp/backup.sh
echo "cp -R /root/.aws /tmp/" >> /tmp/backup.sh
echo "cp -R /homeassistant /tmp/" >> /tmp/backup.sh
echo "cp -R /backup /tmp/" >> /tmp/backup.sh
echo "*/3 * * * * /tmp/backup.sh >> /var/log/copy-files.log 2>&1" >> /etc/crontabs/root
chmod +x /tmp/backup.sh
crond

aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin 654654455942.dkr.ecr.ap-southeast-2.amazonaws.com
docker run -d -u $(id -u):$(id -g) --pull=always --restart=unless-stopped -v /tmp/.aws:/root/.aws -v /tmp/homeassistant:/homeassistant -v /tmp/backup:/backup 654654455942.dkr.ecr.ap-southeast-2.amazonaws.com/home-assistant-helper-$machine_nickname
```

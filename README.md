# Home Assistant Helper

## Features
- Automatically request/renew certs from letsencrypt
- Automatically update R53 records to point to the machine's public IP
- Automatically upload Home Assistant backup files to s3
- Automatically push Home Assistant configuration yaml files to github
- Each machine uses a dedicated AWS user with granular permissions to update a specific DNS record and access a defined S3 bucket path

## Setting up a New Home
### 1. Update GitHub Workflow
Modify `.github/workflows/ci-pipeline.yaml` and add the new machine nickname under `deploy.strategy.matrix.machine-nick-name`. e.g. `home,home2,machine3,new_machine4`. Once pushed, the Github workflow will be triggered to create a new cloud formation stack with aws resources for this machine.

### 2. Retrieve AWS Credentials
In the AWS console, locate the newly created IAM user named `home-assistant-{machine-nick-name}`. Get AWS Secret Access Key and AWS Access Key ID from this user.

### 3. Run Setup Script
SSH into the new Raspberry Pi and run:
```sh
MACHINE_NICKNAME="home" # Replace "home" with the value you defined earlier in the first step, e.g. home2.  
curl -O https://raw.githubusercontent.com/daiyyr/home-assistant-helper/main/scripts/install.sh
chmod +x install.sh
./install.sh "$MACHINE_NICKNAME"
```
You’ll be prompted for the AWS credentials from step 2.

## Recovery After Power Outage
```sh
docker rm homeassistant
ha core start
```

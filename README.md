# Home Assistant Helper Setup Guide

## Features
- Regularly update R53 records to point to the machine's public IP
- Each machine uses a separate AWS user with permissions that can only update a specific DNS record
- Regularly upload Home Assistant backup files to s3
- Regularly push Home Assistant configuration yaml files to github

## Setting up a New Machine
### 1. Update GitHub Workflow
Modify `.github/workflows/ci-pipeline.yaml` and add the new machine nickname under `deploy.strategy.matrix.machine-nick-name`. e.g. `home,home2,machine3,new_machine4`. Once pushed, the Github workflow will be triggered to create a new cloud formation stack with aws resources for this machine.

### 2. Retrieve AWS Credentials
In the AWS console, locate the newly created IAM user named `home-assistant-{machine-nick-name}`. Get AWS Secret Access Key and AWS Access Key ID from this user.

### 3. Run Setup Script on the New Machine

SSH into the new machine and run the setup script:

```sh
curl -O https://raw.githubusercontent.com/daiyyr/home-assistant-helper/main/scripts/install.sh
chmod +x install.sh
./setup-machine.sh `MACHINE_NICKNAME`
```
Replace <MACHINE_NICKNAME> with the value you defined earlier in the first step, e.g. home2.  
You will be prompted to enter AWS Access Key ID and Secret Access Key during the process, enter the one you get from the previous step.

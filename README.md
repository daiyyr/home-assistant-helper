# granular-dynamic-dns
Regularly update R53 records to point to local machine(s) public IP. Each machine use a different AWS user which can only update a specific DNS


# New machine setup
- Update workflows/deploy-dns-updaters.yaml, add a new machine nick name to deploy.strategy.matrix.machine-name, e.g. home1,machine2,machine3,newmachine4. The Github workflow should be triggered to create a new aws user with policies to update the specific dns
- Go to aws console to get AWS Secret Access Key and AWS Access Key ID for that user
- SSH to the new machine, install aws cli and configure AWS CLI with the above AWS credentials. Depending on the OS, you may need to use the relevant package manager to install the AWS CLI. Home Assistant Operating System for Raspberry Pi is based on Alpine Linux, so we use apk:

```
cd /path/to/granular-dynamic-dns # replace "/path/to/granular-dynamic-dns" with the actual path
clone https://github.com/daiyyr/granular-dynamic-dns
apk add aws-cli
aws configure
# enter AWS Secret Access Key and AWS Access Key ID from last step
```

- add a crontab record:

```
crontab -e

# add the below line - replace "/path/to/granular-dynamic-dns" with the actual path
* * * * * /path/to/granular-dynamic-dns/dynamic-dns/update-dns.sh >> /path/to/granular-dynamic-dns/dynamic-dns/update-dns.log 2>&1
```

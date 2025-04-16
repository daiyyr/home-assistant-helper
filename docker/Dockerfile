FROM arm64v8/alpine:3.21.3

# Build arguments
ARG MACHINE_NICKNAME

# Make them available inside the container
ENV MACHINE_NICKNAME=$MACHINE_NICKNAME

ARG AWS_DEFAULT_REGION=ap-southeast-2
ENV AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION

# Install required packages
RUN apk update
RUN apk add --no-cache bash git cronie openrc openssh aws-cli

# Create working directories
RUN mkdir -p /opt/scripts \
    && mkdir -p /root/.cache

# Copy local helper scripts into the correct location inside the container
COPY scripts/* /opt/scripts/

# Add cron jobs
RUN echo "*/5 * * * * /opt/scripts/update-dns.sh >> /var/log/update-dns.log 2>&1" >> /etc/crontabs/root \
    && echo "0 3 * * 0 /opt/scripts/backup-to-s3.sh >> /var/log/s3-backup.log 2>&1" >> /etc/crontabs/root \
    && echo "*/3 * * * * /opt/scripts/push-to-github.sh >/dev/null 2>&1" >> /etc/crontabs/root

# Start crond in foreground
CMD ["crond", "-f", "-l", "2"]

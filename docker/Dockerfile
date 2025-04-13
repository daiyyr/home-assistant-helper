FROM alpine:3.21.3

# Set ARGs and ENV for flexibility
ARG MACHINE_NICKNAME=home
ENV MACHINE_NICKNAME=$MACHINE_NICKNAME
ARG GITHUB_TOKEN
ENV GITHUB_TOKEN=$GITHUB_TOKEN

# Install required packages
RUN apk update && apk add --no-cache \
    bash \
    git \
    aws-cli \
    cronie \
    openrc \
    openssh

# Create working directories
RUN mkdir -p /homeassistant/logs \
    && mkdir -p /homeassistant/home-assistant-helper/scripts \
    && mkdir -p /root/.cache

# Copy local helper scripts into the correct location inside the container
COPY scripts/* /homeassistant/home-assistant-helper/scripts/

# Set the machine nickname
RUN echo "$MACHINE_NICKNAME" > /homeassistant/machine_nickname.txt

# Clone the helper script repo
WORKDIR /homeassistant
RUN git clone https://github.com/daiyyr/home-assistant-helper

# Store Git credentials (bind a pre-configured .git-credentials at runtime)
RUN git config --global credential.helper store \
    && echo "https://home-assistant-raspberry-pi:${GITHUB_TOKEN}@github.com" > /root/.git-credentials

# Clone the Home Assistant config repo
RUN git clone https://github.com/daiyyr/home-assistant-config

# Add cron jobs
RUN echo "*/5 * * * * /homeassistant/home-assistant-helper/scripts/update-dns.sh >> /homeassistant/logs/update-dns.log 2>&1" >> /etc/crontabs/root \
    && echo "0 3 * * 0 /homeassistant/home-assistant-helper/scripts/backup-to-s3.sh >> /homeassistant/logs/s3-backup.log 2>&1" >> /etc/crontabs/root \
    && echo "*/3 * * * * /homeassistant/home-assistant-helper/scripts/push-to-github.sh >/dev/null 2>&1" >> /etc/crontabs/root

# Start crond in foreground
CMD ["crond", "-f", "-l", "2"]

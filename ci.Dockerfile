FROM maven:3.9.6-eclipse-temurin-17
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl wget gnupg ca-certificates unzip fonts-liberation && \
  rm -rf /var/lib/apt/lists/*
RUN install -m 0755 -d /etc/apt/keyrings && \
  wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-linux.gpg && \
  sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-linux.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list' && \
  apt-get update && apt-get install -y --no-install-recommends google-chrome-stable && \
  rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
  apt-get update && apt-get install -y --no-install-recommends nodejs && \
  npm i -g newman && \
  rm -rf /var/lib/apt/lists/*
ENV CHROME_BIN=/usr/bin/google-chrome
WORKDIR /workspace
USER root
FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update && apt-get install -y \
    curl \
    jq \
    tmux \
    wget \
    unzip \
    ca-certificates \
    gnupg

# Install Xray
RUN bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Install Node.js (latest LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs

# base
FROM ubuntu:20.04

# Add a label pointing to our repository
LABEL org.opencontainers.image.source="https://github.com/glassboard-dev/gl-yocto-runner-image"

# set the github runner version
ARG RUNNER_VERSION="2.304.0"
ARG NODE_VERSION="v18.16.0"
ARG DOCKER_VERSION="5:20.10.24~3-0~ubuntu-focal"

# do a non interactive build
ARG DEBIAN_FRONTEND=noninteractive

# update the base packages and add a non-sudo user
RUN apt-get update --fix-missing -y && apt-get upgrade -y && useradd -m runner

# install python and the packages the your code depends on along with jq so we can parse JSON
# add additional packages as necessary
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl \
    jq \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3 \
    python3-venv \
    python3-dev \
    python3-pip \
    python2 \
    python2.7 \
    gawk \
    wget \
    git-core \
    diffstat \
    unzip \
    texinfo \
    gcc-multilib \
    chrpath \
    socat \
    libsdl1.2-dev \
    xterm \
    cpio \
    file \
    xxd \
    locales \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common \
    supervisor \
    zstd \
    lz4

RUN cd /opt \
    && curl -LO https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz \
    && tar xJf node-${NODE_VERSION}-linux-x64.tar.xz \
    && rm node-${NODE_VERSION}-linux-x64.tar.xz
ENV PATH=/opt/node-${NODE_VERSION}-linux-x64/bin:${PATH}

# RUN install -m 0755 -d /etc/apt/keyrings
# RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# RUN chmod a+r /etc/apt/keyrings/docker.gpg

# RUN echo \
#     "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
#     "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
#     tee /etc/apt/sources.list.d/docker.list > /dev/null

# RUN apt-get update
# RUN DEBIAN_FRONTEND=noninteractive apt-get -y install docker-ce=${DOCKER_VERSION} docker-ce-cli=${DOCKER_VERSION}

RUN curl -sSL https://get.docker.com/ | VERSION=20.10.24~3 sh

RUN usermod -aG docker runner
RUN newgrp docker

# Update the locales to UTF-8
RUN locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# cd into the user directory, download and unzip the github actions runner
RUN cd /home/runner && mkdir actions-runner && cd actions-runner \
    && curl -O -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# install some additional dependencies
RUN chown -R runner ~runner && /home/runner/actions-runner/bin/installdependencies.sh

# copy over the start.sh script
COPY start.sh start.sh
COPY modprobe /usr/local/bin/

COPY supervisor/ /etc/supervisor/conf.d/

# make the script executable
RUN chmod +x start.sh /usr/local/bin/modprobe

VOLUME /var/lib/docker

# ENTRYPOINT ["start.sh"]

CMD ["/usr/bin/supervisord", "-n"]

# since the config and run script for actions are not allowed to be run by root,
# set the user to "runner" so all subsequent commands are run as the runner user
# USER runner

# set the entrypoint to the start.sh script
# ENTRYPOINT ["./start.sh"]
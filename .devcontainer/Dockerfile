# Dev container base: Fedora (latest)
FROM fedora:latest

ARG VARIANT=latest
ENV DEBIAN_FRONTEND=noninteractive

# Install base tooling and build deps
RUN dnf -y update \
 && dnf -y install --skip-unavailable \
    cmake \
    curl \
    docker-cli \
    fd-find \
    fish \
    gcc \
    gcc-c++ \
    gh \
    git \
    go \
    htop \
    java-25-openjdk-headless \
    jq \
    libevent-devel \
    libffi-devel \
    libgc-devel \
    libxml2-devel \
    libxslt-devel \
    libyaml-devel \
    llvm \
    lsd \
    make \
    openssl-devel \
    pandoc \
    pkgconfig \
    python3 \
    python3-pip \
    rbspy \
    readline-devel \
    ripgrep \
    ruby \
    rustup \
    scc \
    sudo \
    unzip \
    wget \
    which \
    zlib-devel \
 && dnf -y clean all

# Create a vscode user to match devcontainer defaults
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
 && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
 && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
 && chmod 0440 /etc/sudoers.d/$USERNAME \
 && groupadd --gid 800 docker-codespace \
 && usermod -a -G docker -G docker-codespace $USERNAME

# Add /opt/scripts for devcontainer scripts
RUN mkdir -p /opt/devcontainer/scripts && chown -R $USERNAME:$USERNAME /opt/devcontainer

ARG HOME=/home/$USERNAME
USER $USERNAME
WORKDIR $HOME

# Make sure we have a sane shell environment
ENV PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$HOME/.cargo/bin:$HOME/.bun/bin:$PATH"
ENV DOCKER_API_VERSION=1.43

# Copy helper scripts (they will be executed via postCreateCommand)
# Set ownership to vscode so the non-root user can modify permissions
COPY --chown=vscode:vscode scripts /tmp/devcontainer-scripts
RUN chmod +x /tmp/devcontainer-scripts/*.sh

# Default shell is fish (user choice will be set in setup script)
SHELL ["/bin/bash", "-lc"]

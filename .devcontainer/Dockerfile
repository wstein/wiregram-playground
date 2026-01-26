# Dev container base: Fedora (latest)
FROM fedora:latest

ARG VARIANT=latest
ENV DEBIAN_FRONTEND=noninteractive

# Install base tooling and build deps
RUN dnf -y update \
 && dnf -y install \
    sudo \
    git \
    curl \
    wget \
    jq \
    ripgrep \
    fd-find \
    python3 \
    python3-pip \
    fish \
    pandoc \
    gcc \
    gcc-c++ \
    make \
    cmake \
    pkgconfig \
    openssl-devel \
    libyaml-devel \
    zlib-devel \
    readline-devel \
    libffi-devel \
    libxml2-devel \
    libxslt-devel \
    libevent-devel \
    libgc-devel \
    llvm \
    java-17-openjdk-headless \
    which \
 && dnf -y clean all

# Create a vscode user to match devcontainer defaults
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
 && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
 && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
 && chmod 0440 /etc/sudoers.d/$USERNAME

# Add /opt/scripts for devcontainer scripts
RUN mkdir -p /opt/devcontainer/scripts && chown -R $USERNAME:$USERNAME /opt/devcontainer

USER $USERNAME
WORKDIR /home/$USERNAME

# Make sure we have a sane shell environment
ENV PATH="$HOME/.asdf/bin:$HOME/.asdf/shims:$HOME/.cargo/bin:$HOME/.bun/bin:$PATH"

# Copy helper scripts (they will be executed via postCreateCommand)
COPY .devcontainer/scripts /tmp/devcontainer-scripts
RUN chmod +x /tmp/devcontainer-scripts/*.sh

# Default shell is fish (user choice will be set in setup script)
SHELL ["/bin/bash", "-lc"]

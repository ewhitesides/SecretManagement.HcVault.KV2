# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.241.1/containers/ubuntu/.devcontainer/base.Dockerfile

# [Choice] Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): ubuntu-22.04, ubuntu-20.04, ubuntu-18.04
ARG VARIANT="jammy"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

#install vault
RUN version='1.11.0'; \
    wget "https://releases.hashicorp.com/vault/${version}/vault_${version}_linux_amd64.zip" && \
    unzip "vault_${version}_linux_amd64.zip" && \
    mv vault /usr/local/bin && chmod +x /usr/local/bin/vault

#install starship
RUN sudo apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && sudo apt-get -y install --no-install-recommends fonts-firacode && \
    wget https://starship.rs/install.sh && chmod +x install.sh && ./install.sh --yes && rm install.sh

#handy utilities
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive && \
    apt-get -y install --no-install-recommends tree

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

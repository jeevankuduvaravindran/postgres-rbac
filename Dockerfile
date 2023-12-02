ARG IMAGE_TAG=lts-7.2-ubuntu-22.04

FROM mcr.microsoft.com/powershell:${IMAGE_TAG}

# Use root user for installation
USER root
# Install Git
RUN apt-get update && apt-get install -y git

# # Install Azure CLI
# RUN curl -skL https://aka.ms/InstallAzureCLIDeb | bash

ARG DEBIAN_FRONTEND=noninteractive
RUN apt install -y -f postgresql postgresql-contrib

# Change default shell to powershell
SHELL ["pwsh", "-Command"]

# Clone the repo and Run the powershell script and pass the params to it
CMD git clone $env:GIT_REPO_URL; $paramsArg="-Params `"$env:PARAMS`""; $cmd ="pwsh -File $env:SCRIPT_FILE_NAME $paramsArg"; Invoke-Expression $cmd
RUN pwsh -Command Install-Module -Name Az -Repository PSGallery -Force -AllowClobber

# Copy scripts and set permissions
# COPY ./scripts /scripts
# RUN chmod +x /scripts/*

# ENV SYSTEM_DEBUG="true"
# CMD scripts/grant-pg-server-access.ps1

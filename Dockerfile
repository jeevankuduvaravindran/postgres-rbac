ARG IMAGE_TAG=lts-7.2-ubuntu-22.04

FROM mcr.microsoft.com/powershell:${IMAGE_TAG}

# Use root user for installation
USER root
# Install Git
RUN apt-get update && apt-get install -y git

# Change default shell to powershell
SHELL ["pwsh", "-Command"]

# Clone the repo and Run the powershell script and pass the params to it
CMD git clone $env:GIT_REPO_URL; $paramsArg="-Params `"$env:PARAMS`""; $cmd ="pwsh -File $env:SCRIPT_FILE_NAME $paramsArg"; Invoke-Expression $cmd

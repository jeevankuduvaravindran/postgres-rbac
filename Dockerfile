ARG IMAGE_TAG=lts-7.2-ubuntu-22.04

FROM mcr.microsoft.com/powershell:${IMAGE_TAG}
# Argument to capture git URL to be cloned where the powershell script exists
ARG GIT_REPO_URL=https://github.com/jeevankuduvaravindran/postgres-rbac.git
# Argument to capture the name of the powershell script to be executed
ARG SCRIPT_FILE_NAME=postgres-rbac/scripts/script.ps1
# Argument to capture comma separated key value pairs of params that needs to be passed to the powershell script
ARG PARAMS=x=1,y=2

# ENV GIT_REPO_URL=$GIT_REPO_URL
ENV SCRIPT_FILE_NAME=$SCRIPT_FILE_NAME
ENV PARAMS=$PARAMS

USER root
# Install Git
RUN apt-get update && apt-get install -y git
# Clone the git repo
RUN git clone $GIT_REPO_URL

# Run the powershell script and pass the params to it
CMD ["pwsh", "-Command", "Invoke-Expression 'pwsh -File $env:SCRIPT_FILE_NAME -Params $env:PARAMS'"]
# CMD ["pwsh", "-Command", "Write-Host $env:SCRIPT_FILE_NAME"]

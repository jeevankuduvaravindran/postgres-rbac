ARG IMAGE_TAG=lts-7.2-ubuntu-22.04
FROM mcr.microsoft.com/powershell:${IMAGE_TAG}

# Argument to capture git URL to be cloned where the powershell script exists
ARG GIT_REPO_URL
# Argument to capture the name of the powershell script to be executed
ARG SCRIPT_FILE_NAME
# Argument to capture comma separated key value pairs of params that needs to be passed to the powershell script
ARG PARAMS

USER root
# Install Git
RUN apt-get update && apt-get install -y git
# Clone the git repo
RUN git clone $GIT_REPO_URL

# Switch to the scripts directory in git repo
# WORKDIR /repo/scripts

# Run the powershell script and pass the params to it
CMD pwsh -File $SCRIPT_FILE_NAME -Params $PARAMS
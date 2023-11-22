ARG IMAGE_TAG=lts-7.2-ubuntu-22.04
# Argument to capture git URL to be cloned where the powershell script exists
ARG GIT_REPO_URL
# Argument to capture the name of the powershell script to be executed
ARG SCRIPT_FILE_NAME
# Argument to capture comma separated key value pairs of params that needs to be passed to the powershell script
ARG PARAMS

FROM mcr.microsoft.com/powershell:${IMAGE_TAG}

USER root
# Install Git
RUN apt-get update && apt-get install -y git

# Clone the git repo
# Run the powershell script and pass the params to it
CMD ["pwsh", "-Command", "git clone $GIT_REPO_URL && $SCRIPT_FILE_NAME -Params $PARAMS"]
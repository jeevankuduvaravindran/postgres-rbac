# Run Powershell scripts from docker container

## Description

This project is to run a powershell script from docker container.

## Arguments

 - GIT_REPO_URL - Public git repo url that contains the script
 - SCRIPT_FILE_NAME - Location of powershell script along with the path from root of the container image
 - PARAMS - Parameters to be passed to the powershell script if any. Comma separated key value pairs

## Execution

Below the example execution command for the container built with the image.
```
docker run -e GIT_REPO_URL=https://github.com/jeevankuduvaravindran/postgres-rbac.git -e SCRIPT_FILE_NAME=postgres-rbac/scripts/script.ps1 -e PARAMS=x=1,y=2 powershell-runner:dev 
```
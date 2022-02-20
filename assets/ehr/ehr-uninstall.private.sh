#!/bin/bash
set -e

function output {
  echo 'uninstall-ehr.sh:' $1
}

# --------------------------------------------------------------------------------
# script to install hls-ehr docker-compose stack
# --------------------------------------------------------------------------------
output 'uninstalling hls-ehr docker-compose stack'

# --------------------------------------------------------------------------------
output 'looking for existing installation ...'
if [ "$(docker ps --all | grep openemr_app)" ]; then
  output 'found existing installation'
else
  output 'no existing installation!!!'
  exit 1
fi

# --------------------------------------------------------------------------------
output 'removing existing installation'
docker-compose --project-name 'hls-ehr' down

output 'removing docker volumes for hls-ehr'
docker volume prune --force


output 'uninstallation of hls-ehr complete!'

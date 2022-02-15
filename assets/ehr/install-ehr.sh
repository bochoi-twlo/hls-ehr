#!/bin/bash
set -e

function output {
  echo 'install-ehr.sh:' $1;
}

# --------------------------------------------------------------------------------
# script to install hls-ehr docker-compose stack
# --------------------------------------------------------------------------------
output 'installing hls-ehr docker-compose stack';

# --------------------------------------------------------------------------------
output 'looking for existing installation ...'
if [ "$(docker ps --all | grep openemr_app)" ]; then
  output 'found existing installation!!! uninstall via uninstall.sh';
  exit 1;
else
  output 'no existing installation. proceeding ...';
fi

# --------------------------------------------------------------------------------
output 'installing docker-compose stack';
docker compose --project-name 'hls-ehr' up --no-start;

# this is needed for attached docker volumes to properly initialize
output 'initializing docker-compose stack';
docker compose --project-name 'hls-ehr' start;

output 'wait 30 seconds ...';
sleep 30;


output 'installation of hls-ehr complete!';



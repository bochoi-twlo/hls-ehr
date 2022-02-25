#!/bin/bash
set -e

function output {
  echo 'ehr-install.sh:' $1
}

# --------------------------------------------------------------------------------
# script to install hls-ehr docker compose stack
# --------------------------------------------------------------------------------
output 'installing hls-ehr docker compose stack'

output 'looking for existing installation ...'
if [ "$(docker ps --all | grep openemr_app)" ]; then
  output 'found existing installation!!! uninstall via uninstall.sh'
  exit 1
else
  output 'no existing installation. proceeding ...'
fi

output 'installing docker compose stack'
docker-compose --project-name 'hls-ehr' up --no-start

# this is needed for attached docker volumes to properly initialize
output 'initializing docker compose stack'
docker-compose --project-name 'hls-ehr' start

output 'waiting for openemr_app to start up ...'
while [ ! "$(docker exec openemr_app curl --silent --head 'http://openemr_app:80/interface/login/login.php?site=default')" ]; do
  sleep 2
  echo -n '.'
done
echo ' up'

output 'waiting for mirth_app to start up ...'
while [ ! "$(docker exec mirth_app curl --silent --insecure --head https://mirth_app:8443)" ]; do
  sleep 2
  echo -n '.'
done
echo ' up'

output 'waiting for openemr_ie to start up ...'
while [ ! "$(docker exec openemr_ie curl --silent --insecure --head https://openemr_ie:8443)" ]; do
  sleep 2
  echo -n '.'
done
echo ' up'

output 'waiting for mirth_app API to start up ...'
while [ ! "$(docker exec mirth_app curl --silent --insecure --head https://mirth_app:8443/api/)" ]; do
  sleep 2
  echo -n '.'
done
echo ' up'

output 'waiting for openemr_ie API to start up ...'
while [ ! "$(docker exec openemr_ie curl --silent --insecure --head https://openemr_ie:8443/api)" ]; do
  sleep 2
  echo -n '.'
done
echo ' up'


output 'installation of hls-ehr complete!'



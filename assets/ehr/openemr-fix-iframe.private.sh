#!/bin/bash
set -e

function output {
  echo 'openemr-fix-iframe.sh:' $1
}

# --------------------------------------------------------------------------------
# script to fix iframe
# --------------------------------------------------------------------------------
# check hls-ehr
if [ "$(docker ps --all | grep openemr_app)" ]; then
  output 'found hls-ehr docker-compose stack. proceeding ...'
else
  output 'no hls-ehr docker-compose stack!!! exiting ...'
  exit 1
fi

# ---------- main execution ----------------------------------------------------------------------
if [ "$(docker ps | grep openemr_app)" ]; then
  # currently running
  docker exec -i openemr_app /bin/sh < openemr/script_iframe_fix.sh
else
  # currently not running
  docker start openemr_app

  docker exec -i openemr_app /bin/sh < openemr/script_iframe_fix.sh

  docker stop openemr_app
fi

output 'complete'

#!/bin/bash
set -e

function output {
  echo 'openemr-restore-volumes.sh:' $1
}

# --------------------------------------------------------------------------------
# script to restore openemr volumes to deployed hls-ehr
#
# to be run inside Docker installer container or locally during development
# working directory needs to be this directory along with volume backups tar.gz files
# --------------------------------------------------------------------------------
VOLUME_HELPER='hls-volume-helper'
if [ -z ${1} ]; then
  BACKUP_NAME='sko'
else
  BACKUP_NAME=${1}
fi

# check hls-ehr
if [ "$(docker ps --all | grep openemr_app)" ]; then
  output 'found ehr docker-compose stack. proceeding ...'
else
  output 'no ehr docker-compose stack!!! exiting ...'
  exit 1
fi


# --------------------------------------------------------------------------------
# ensure removal of orphaned helper container on error exit
function cleanup {
  if [ "$(docker ps --all | grep ${VOLUME_HELPER})" ]; then
    docker rm --force ${VOLUME_HELPER}
  fi
}
trap cleanup EXIT

# --------------------------------------------------------------------------------
function restore_volume {
  DOCKER_CONTAINER=${1}
  BACKUP_FILE=${2}

  output "restore volume on CONTAINER=${DOCKER_CONTAINER} from ${BACKUP_FILE}"
  if [ ! -f "${BACKUP_FILE}" ]; then
    output "${BACKUP_FILE} not found!!!"
    exit 1
  fi

  docker run --name ${VOLUME_HELPER} --volumes-from ${DOCKER_CONTAINER} --interactive --detach ubuntu
  while [ ! "$(docker ps | grep ${VOLUME_HELPER})" ]; do
    output "${VOLUME_HELPER} not running yet"
    sleep 1
  done

  docker cp ${BACKUP_FILE} ${VOLUME_HELPER}:${BACKUP_FILE}

  docker exec ${VOLUME_HELPER} tar -zxf ${BACKUP_FILE}

  docker rm --force ${VOLUME_HELPER}
  while [ "$(docker ps --all | grep ${VOLUME_HELPER})" ]; do
    output "${VOLUME_HELPER} not removed yet"
    sleep 1
  done
}

# ---------- main execution ----------------------------------------------------------------------

restore_volume 'openemr_db' "openemr_db_${BACKUP_NAME}.tar.gz"
restore_volume 'openemr_app' "openemr_app_${BACKUP_NAME}.tar.gz"

output 'complete'

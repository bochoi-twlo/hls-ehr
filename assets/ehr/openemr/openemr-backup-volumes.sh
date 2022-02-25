#!/bin/bash
set -e

function output {
  echo 'openemr-backup-volumes.sh:' $1
}

# --------------------------------------------------------------------------------
# script to backup openemr volumes to deployed hls-ehr
# --------------------------------------------------------------------------------
VOLUME_HELPER='hls-volume-helper'
if [ -z ${1} ]; then
  echo 'Usage: ./openemr-backup-volumes your-backup-name';
  exit 1;
fi
BACKUP_NAME=${1}

# check hls-ehr
EXISTS=$(docker container ls --all | grep openemr_app | wc -l)
if [ "$(docker ps --all | grep openemr_app)" ]; then
  echo 'found hls-ehr docker compose stack. proceeding ...';
else
  echo 'no hls-ehr docker compose stack!!! exiting ...';
  exit 1;
fi

# --------------------------------------------------------------------------------
function cleanup {
  if [ "$(docker ps --all | grep ${VOLUME_HELPER})" ]; then
    docker rm --force ${VOLUME_HELPER}
  fi
}
trap cleanup EXIT

# --------------------------------------------------------------------------------
function backup_volume {
  DOCKER_CONTAINER=${1}
  BACKUP_TARFILE=${2}
  DIRECTORY=${3}

  output "backup volume mounted at ${DIRECTORY} on CONTAINER=${DOCKER_CONTAINER} to ${BACKUP_TARFILE}.gz"

  # remove previous file if any
  [[ -f ${BACKUP_TARFILE}.gz ]] && rm ${BACKUP_TARFILE}.gz
  [[ -f ${BACKUP_TARFILE} ]] && rm ${BACKUP_TARFILE}

  docker run --name ${VOLUME_HELPER} --volumes-from ${DOCKER_CONTAINER} --interactive --detach ubuntu

  docker exec ${VOLUME_HELPER} tar -cf ${BACKUP_TARFILE} --exclude='*ib_logfile0' ${DIRECTORY}
  docker cp ${VOLUME_HELPER}:${BACKUP_TARFILE} ${BACKUP_TARFILE}
  gzip --best --force ${BACKUP_TARFILE}

  docker rm --force ${VOLUME_HELPER}
}


# ---------- main execution ----------------------------------------------------------------------
output 'stopping docker compose stack'
docker-compose --project-name 'hls-ehr' stop

backup_volume 'openemr_db' "openemr_db_${BACKUP_NAME}.tar" '/var/lib/mysql'
backup_volume 'openemr_app' "openemr_app_${BACKUP_NAME}.tar" '/var/www/localhost/htdocs/openemr/sites'

output 'starting docker-compose stack'
docker-compose --project-name 'hls-ehr' start

output 'complete'

exit 0

# --------------------------------------------------------------------------------
# this version cannot run in docker-in-docker as only host directories can be bind mounted by container
function backup_volume_old {
  DOCKER_CONTAINER=${1}
  BACKUP_TARFILE=${2}
  DIRECTORY=${3}

  echo "backup volume mounted at ${DIRECTORY} on DOCKER_CONTAINER=${DOCKER_CONTAINER} to ${BACKUP_TARFILE}"

  [[ -f ${BACKUP_TARFILE} ]] && rm ${BACKUP_TARFILE}

  docker run --rm --volumes-from ${DOCKER_CONTAINER} --volume $(pwd):/backup ubuntu \
    tar cf /backup/${BACKUP_TARFILE} ${DIRECTORY}

  gzip --best --force ${BACKUP_TARFILE}
  # aws s3 cp ${BACKUP_TARFILE}.gz s3://${S3BUCKET_ARTIFACTS}/appointments/${BACKUP_TARFILE}.gz --sse

  # rm ${BACKUP_TARFILE}.gz
}

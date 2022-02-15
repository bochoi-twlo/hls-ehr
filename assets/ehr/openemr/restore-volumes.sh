#!/bin/bash
set -e;
# --------------------------------------------------------------------------------
# script to restore openemr volumes to deployed hls-ehr
# --------------------------------------------------------------------------------
if [ -z ${1} ]; then
  echo 'Usage: ./restore-volumes your-backup-name';
  exit 1;
fi
BACKUP_NAME=${1};

# check hls-ehr
EXISTS=$(docker container ls --all | grep openemr_app | wc -l);
if [ $EXISTS == '0' ]; then
  echo 'no hls-ehr docker-compose stack!!! exiting ...';
  exit 1;
else
  echo 'found hls-ehr docker-compose stack. proceeding ...';
fi

# --------------------------------------------------------------------------------
function cleanup {
  [ "$(docker ps --all | grep hls-helper)" ] && docker rm --force hls-helper;
}
trap cleanup EXIT

# --------------------------------------------------------------------------------
function restore_volume {
  DOCKER_CONTAINER=${1};
  BACKUP_TARFILE=${2};

  echo "restore volume on CONTAINER=${DOCKER_CONTAINER} from ${BACKUP_TARFILE}.gz";
  if [ ! -f "${BACKUP_TARFILE}.gz" ]; then
    echo "${BACKUP_TARFILE}.gz not found!!!";
    exit 1;
  fi

  gunzip --stdout ${BACKUP_TARFILE}.gz > ${BACKUP_TARFILE};

  docker run --name 'hls-helper' --volumes-from ${DOCKER_CONTAINER} -i -d ubuntu;

  docker cp ${BACKUP_TARFILE} hls-helper:${BACKUP_TARFILE};
  docker exec hls-helper tar -xf ${BACKUP_TARFILE};

  docker rm --force hls-helper;
  echo "... done";
}

# ---------- main execution ----------------------------------------------------------------------
echo 'stopping docker-compose stack';
docker compose --project-name 'hls-ehr' stop;

restore_volume 'openemr_db' "openemr_db_${BACKUP_NAME}.tar";
restore_volume 'openemr_app' "openemr_app_${BACKUP_NAME}.tar";

echo 'starting docker-compose stack';
docker compose --project-name 'hls-ehr' start;


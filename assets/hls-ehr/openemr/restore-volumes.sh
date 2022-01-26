#!/bin/zsh
set -e

function restore_volume {
  DOCKER_CONTAINER=${1}
  BACKUP_TARFILE=${2}

  echo
  echo "restore volume on CONTAINER=${DOCKER_CONTAINER} from ${BACKUP_TARFILE}.gz"

  gunzip --stdout ${BACKUP_TARFILE}.gz > ${BACKUP_TARFILE}

  # note the untar location is /var to restore var/lib/mysql
  docker run --rm --volumes-from ${DOCKER_CONTAINER} --volume $(pwd):/backup ubuntu \
    bash -c "cd /var && tar xf /backup/${BACKUP_TARFILE} --strip 1"

  rm ${BACKUP_TARFILE}
  echo
}


if [ -z ${1} ]; then
  echo 'Usage: ./restore-volume your-backup-name';
#  echo '  - default s3 location is s3://twlo-hls-artifacts/hls-flex-sko-demo';
  exit 1;
fi
BACKUP_NAME=${1}

BACKUP_DB="openemr_db_${BACKUP_NAME}"
if [ ! -f "${BACKUP_DB}.tar.gz" ]; then
  echo "${BACKUP_DB}.tar.gz not found!";
  exit 1;
fi
BACKUP_APP="openemr_app_${BACKUP_NAME}"
if [ ! -f "${BACKUP_APP}.tar.gz" ]; then
  echo "${BACKUP_APP}.tar.gz not found!";
  exit 1;
fi
echo 'Restoring backups:'
echo '  '${BACKUP_DB}'.tar.gz'
echo '  '${BACKUP_APP}'.tar.gz'


docker-compose stop

restore_volume 'openemr_db' "${BACKUP_DB}.tar"

restore_volume 'openemr_app' "${BACKUP_APP}.tar"

docker-compose start

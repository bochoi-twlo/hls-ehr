#!/bin/bash
set -e

function backup_volume {
  DOCKER_CONTAINER=${1}
  BACKUP_TARFILE=${2}
  DIRECTORY=${3}

  echo
  echo "backup volume mounted at ${DIRECTORY} on DOCKER_CONTAINER=${DOCKER_CONTAINER} to ${BACKUP_TARFILE}"

  [[ -f ${BACKUP_TARFILE} ]] && rm ${BACKUP_TARFILE}

  docker run --rm --volumes-from ${DOCKER_CONTAINER} --volume $(pwd):/backup ubuntu \
    tar cf /backup/${BACKUP_TARFILE} ${DIRECTORY}

  gzip --best --force ${BACKUP_TARFILE}
  # aws s3 cp ${BACKUP_TARFILE}.gz s3://${S3BUCKET_ARTIFACTS}/appointments/${BACKUP_TARFILE}.gz --sse

  # rm ${BACKUP_TARFILE}.gz
  echo
}


if [ -z ${1} ]; then
  echo 'Usage: ./backup-volume your-backup-name';
#  echo '  - default s3 location is s3://twlo-hls-artifacts/hls-flex-sko-demo';
  exit 1;
fi
BACKUP_NAME=${1}
BACKUP_DB="openemr_db_${BACKUP_NAME}"
BACKUP_APP="openemr_app_${BACKUP_NAME}"
echo 'Creating backups:'
echo '  '${BACKUP_DB}'.tar.gz'
echo '  '${BACKUP_APP}'.tar.gz'


docker-compose stop

backup_volume 'openemr_db' "${BACKUP_DB}.tar" '/var/lib/mysql'

backup_volume 'openemr_app' "${BACKUP_APP}.tar" '/var/www/localhost/htdocs/openemr/sites'

docker-compose start


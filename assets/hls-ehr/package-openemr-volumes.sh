#!/bin/bash
set -e

S3BUCKET_ARTIFACTS='twlo-hls-artifacts'

function backup_volume {
  CONTAINER=${1}
  DIRECTORY=${2}
  BACKUP_TARFILE="backup_${CONTAINER}_volumes.tar"

  echo
  echo "backup volume mounted at ${DIRECTORY} on CONTAINER=${CONTAINER}"

  [[ -f ${BACKUP_TARFILE} ]] && rm ${BACKUP_TARFILE}

  docker run --rm --volumes-from ${CONTAINER} --volume $(pwd):/backup ubuntu \
    tar cf /backup/${BACKUP_TARFILE} ${DIRECTORY}

  gzip --best --force ${BACKUP_TARFILE}
  aws s3 cp ${BACKUP_TARFILE}.gz s3://${S3BUCKET_ARTIFACTS}/appointments/${BACKUP_TARFILE}.gz --sse

  rm ${BACKUP_TARFILE}.gz
  echo
}


docker-compose stop

backup_volume 'openemrdb' '/var/lib/mysql'

backup_volume 'openemr' '/var/www/localhost/htdocs/openemr/sites'

docker-compose start


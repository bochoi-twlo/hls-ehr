#!/bin/zsh
set -e

function restore_volume {
  CONTAINER=${1}
  BACKUP_TARFILE="backup_${CONTAINER}_volumes.tar"

  echo
  echo "restore volume on CONTAINER=${CONTAINER} from ${BACKUP_TARFILE}.gz"

  gunzip --stdout ${BACKUP_TARFILE}.gz > ${BACKUP_TARFILE}

  # note the untar location is /var for restore var/lib/mysql
  docker run --rm --volumes-from ${CONTAINER} --volume $(pwd):/backup ubuntu \
    bash -c "cd /var && tar xf /backup/${BACKUP_TARFILE} --strip 1"

  rm ${BACKUP_TARFILE}
  echo
}


docker-compose stop

restore_volume 'openemr_db'

restore_volume 'openemr_app'

docker-compose start

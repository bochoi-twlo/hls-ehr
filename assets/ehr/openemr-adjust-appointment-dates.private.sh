#!/bin/bash
set -e
# --------------------------------------------------------------------------------
# script to configure openemr
#
# to be run inside Docker installer container or locally during development
# working directory needs to be this directory along with other referenced files
# --------------------------------------------------------------------------------
# check hls-ehr
EXISTS=$(docker container ls --all | grep openemr_app | wc -l)
if [ $EXISTS == '0' ]; then
  echo 'no hls-ehr docker-compose stack!!! exiting ...';
  exit 1;
else
  echo 'found hls-ehr docker-compose stack. proceeding ...';
fi

# --------------------------------------------------------------------------------
# MUST ensure no triggers are enabled on openemr.openemr_postcalendar_events table
function adjust_appointment_dates {
  echo 'adjusting appointment dates to this week'

  sql='select MIN(pc_eventDate) as min_pc_eventDate from openemr.openemr_postcalendar_events'
  ANCHOR_YYYYMMDD=$(docker exec openemr_db mysql --user=root --password=root --silent openemr --execute "${sql}")

  sql='select CAST(MIN(UNIX_TIMESTAMP(pc_eventDate))/86400 AS INT) as min_pc_eventDate_days_since_epoch from openemr.openemr_postcalendar_events'
  ANCHOR_DAYS_EPOCH=$(docker exec openemr_db mysql --user=root --password=root --silent openemr --execute "${sql}")
  echo "earliest appointment date in openEMR is ${ANCHOR_YYYYMMDD}, ${ANCHOR_DAYS_EPOCH} days since epoch"

  TODAY_YYYYMMDD=$(date +%Y-%m-%d)
  TODAY_DAYS_EPOCH=$((`date +%s` / 86400 ))
  echo "today is ${TODAY_YYYYMMDD}, ${TODAY_DAYS_EPOCH} days since epoch"

  DIFF_DAYS=$((TODAY_DAYS_EPOCH - ANCHOR_DAYS_EPOCH))
  DIFF_WEEKS=$(((TODAY_DAYS_EPOCH - ANCHOR_DAYS_EPOCH) / 7))
  echo "difference is ${DIFF_DAYS} or ${DIFF_WEEKS} whole (to Monday) weeks"

  ADJUST_DAYS=$((DIFF_WEEKS * 7))
  echo "adjusting forward ${ADJUST_DAYS} days"

  sql="update openemr.openemr_postcalendar_events set pc_eventDate = date_add(pc_eventDate, interval ${ADJUST_DAYS} day)"
  echo $sql
  docker exec openemr_db mysql --user=root --password=root --silent openemr --execute "${sql}"

  sql="update openemr.openemr_postcalendar_events set pc_endDate = date_add(pc_endDate, interval ${ADJUST_DAYS} day) where pc_endDate <> '0000-00-00'"
  echo $sql
  docker exec openemr_db mysql --user=root --password=root --silent openemr --execute "${sql}"
}

# ---------- main execution ----------------------------------------------------------------------

echo 'stopping docker openemr_app'
docker stop openemr_app

adjust_appointment_dates

echo 'starting docker openemr_app'
docker start openemr_app

#!/bin/bash
set -e

function output {
  echo 'openemr-adjust-appointment-dates.sh:' $1
}

# --------------------------------------------------------------------------------
# script to configure openemr
#
# working directory MUST be current directory (assets/ehr)
#
# to be run inside Docker installer container or locally during development
# working directory needs to be this directory along with other referenced files
# --------------------------------------------------------------------------------
# check hls-ehr
if [ "$(docker ps --all | grep openemr_app)" ]; then
  output 'found hls-ehr docker compose stack. proceeding ...';
else
  output 'no hls-ehr docker compose stack!!! exiting ...';
  exit 1;
fi

# --------------------------------------------------------------------------------
# MUST ensure no triggers are enabled on openemr.openemr_postcalendar_events table
function adjust_appointment_dates {
  output 'adjusting appointment dates to this week'

  sql='select MIN(pc_eventDate) as min_pc_eventDate from openemr.openemr_postcalendar_events'
  ANCHOR_YYYYMMDD=$(docker exec openemr_db mysql --user=root --password=root --silent openemr --execute "${sql}")

  sql='select CAST(MIN(UNIX_TIMESTAMP(pc_eventDate))/86400 AS INT) as min_pc_eventDate_days_since_epoch from openemr.openemr_postcalendar_events'
  ANCHOR_DAYS_EPOCH=$(docker exec openemr_db mysql --user=root --password=root --silent openemr --execute "${sql}")
  output "earliest appointment date in openEMR is ${ANCHOR_YYYYMMDD}, ${ANCHOR_DAYS_EPOCH} days since epoch"

  TODAY_YYYYMMDD=$(date +%Y-%m-%d)
  TODAY_DAYS_EPOCH=$((`date +%s` / 86400 ))
  output "today is ${TODAY_YYYYMMDD}, ${TODAY_DAYS_EPOCH} days since epoch"

  DIFF_DAYS=$((TODAY_DAYS_EPOCH - ANCHOR_DAYS_EPOCH))
  DIFF_WEEKS=$(((TODAY_DAYS_EPOCH - ANCHOR_DAYS_EPOCH) / 7))
  output "difference is ${DIFF_DAYS} or ${DIFF_WEEKS} whole (to Monday) weeks"

  ADJUST_DAYS=$((DIFF_WEEKS * 7))
  output "adjusting forward ${ADJUST_DAYS} days"

  sql="update openemr.openemr_postcalendar_events set pc_eventDate = date_add(pc_eventDate, interval ${ADJUST_DAYS} day)"
  output $sql
  docker exec openemr_db mysql --user=root --password=root --silent openemr --execute "${sql}"

  sql="update openemr.openemr_postcalendar_events set pc_endDate = date_add(pc_endDate, interval ${ADJUST_DAYS} day) where pc_endDate <> '0000-00-00'"
  output $sql
  docker exec openemr_db mysql --user=root --password=root --silent openemr --execute "${sql}"
}

# ---------- main execution ----------------------------------------------------------------------

output 'stopping docker openemr_app'
docker stop openemr_app

output 'disabling (drop) triggers'
docker exec -i openemr_db mysql --user=root --password=root openemr < openemr/drop_all_triggers.sql

adjust_appointment_dates

output 're-enabling (create) triggers'
docker exec --interactive openemr_db mysql --user=root --password=root openemr < openemr/create_appointment_insert_trigger.sql
docker exec --interactive openemr_db mysql --user=root --password=root openemr < openemr/create_appointment_update_trigger.sql
docker exec --interactive openemr_db mysql --user=root --password=root openemr < openemr/create_patient_update_trigger.sql


output 'starting docker openemr_app'
docker start openemr_app

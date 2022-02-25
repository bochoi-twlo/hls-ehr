#!/bin/bash
set -e

function output {
  echo 'mirth-deploy-channels.sh:' $1
}

# --------------------------------------------------------------------------------
# script to deploy mirth channels
#
# working directory MUST be current directory (assets/ehr)
#
# to be run inside Docker installer container or locally during development
# working directory needs to be this directory along with other referenced files
# --------------------------------------------------------------------------------
# check mirth
if [ "$(docker ps | grep mirth_app)" ]; then
  output 'found running mirth_app docker container. proceeding ...';
else
  output 'no running mirth_app docker container!!! exiting ...';
  exit 1;
fi

# check openemr_ie
if [ "$(docker ps | grep openemr_ie)" ]; then
  output 'found running openemr_ie docker container. proceeding ...';
else
  output 'no running openemr_ie docker container!!! exiting ...';
  exit 1;
fi

# check twilio credentials
if [[ -z ${ACCOUNT_SID} ]]; then
  output 'ACCOUNT_SID environment variable unset!!!'
  exit 1
fi

if [[ -z ${AUTH_TOKEN} ]]; then
  output 'AUTH_TOKEN environment variable unset!!!'
  exit 1
fi

# check deployed PAM
FLOW_SID=$(curl https://studio.twilio.com/v2/Flows --silent --user ${ACCOUNT_SID}:${AUTH_TOKEN} \
  | jq --raw-output '.flows[] | select(.friendly_name | contains("'patient-appointment-management'")) | .sid')
if [[ -z ${FLOW_SID} ]]; then
  output "sid not found for flows[].friendly_name=patient-appointment-management!!!"
  exit 1
else
  output "found patient-appointment-management studio flow: ${FLOW_SID}"
fi

FLOW_PHONE_NUMBER=$(curl https://preview.twilio.com/Numbers/ActiveNumbers \
  --silent --user ${ACCOUNT_SID}:${AUTH_TOKEN} \
  | jq --raw-output '.items[] | select(.configurations.sms.url | contains("'${FLOW_SID}'")) | .phone_number')
if [[ -z ${FLOW_PHONE_NUMBER} ]]; then
  output "phone_number not found for flow_sid=${FLOW_SID}!!!"
  exit 1
else
  output "found patient-appointment-management phone: ${FLOW_PHONE_NUMBER}"
fi

# --------------------------------------------------------------------------------
#
# --------------------------------------------------------------------------------
function deploy_channel {
  URL_N_PORT=${1}
  CHANNEL_NAME=${2}
  output "deploying channel to ${URL_N_PORT}"
  output "CHANNEL_NAME=${CHANNEL_NAME}"

  # check channel file
  CHANNEL_FILE="mirth/${CHANNEL_NAME}.template.xml"
  if [ -f "${CHANNEL_FILE}" ]; then
    output "CHANNEL_FILE=${CHANNEL_FILE}"
  else
    output "${CHANNEL_FILE} not found!!!"
    exit 1
  fi

  # retrive channel id from file
  CHANNEL_ID=$(xq --raw-output .channel.id ${CHANNEL_FILE})
  output "CHANNEL_ID=${CHANNEL_ID}"

  # check if channel is already deployed
  DEPLOYED=$(curl --silent --insecure --request GET "https://${URL_N_PORT}/api/channels/${CHANNEL_ID}" --user admin:admin)
  if [[ -z "${DEPLOYED}" ]]; then
    output "channel not deployed previously, proceeding ..."
  else
    output "channel deployed previously, so deleting ..."
    output "deleting CHANNEL_NAME=${CHANNEL_NAME} ... "
    curl --silent --insecure --request DELETE "https://${URL_N_PORT}/api/channels/${CHANNEL_ID}" --user admin:admin
  fi

  output "creating deployable channel file: ${CHANNEL_NAME}.xml"
  if [[ "${CHANNEL_NAME}" != 'appointments-emr2twlo' ]]; then
    cat ${CHANNEL_FILE} > ${CHANNEL_NAME}.xml
  else
    output "replace YOUR_TWILIO_ACCOUNT_SID with ${ACCOUNT_SID}"
    output "replace YOUR_TWILIO_AUTH_TOKEN with ${AUTH_TOKEN}"
    output "replace YOUR_FLOW_SID with ${FLOW_SID}"
    output "replace YOUR_FLOW_PHONE_NUMBER with ${FLOW_PHONE_NUMBER}"

    cat ${CHANNEL_FILE} \
      | sed "s/YOUR_TWILIO_ACCOUNT_SID/${TWILIO_ACCOUNT_SID}/g" \
      | sed "s/YOUR_TWILIO_AUTH_TOKEN/${TWILIO_AUTH_TOKEN}/g" \
      | sed "s/YOUR_FLOW_SID/${FLOW_SID}/g" \
      | sed "s/YOUR_FLOW_PHONE_NUMBER/${FLOW_PHONE_NUMBER}/g" \
      > ${CHANNEL_NAME}.xml
  fi
  if [ ! -f "${CHANNEL_NAME}.xml" ]; then
    output "error creating ${CHANNEL_NAME}.xml!!!"
    exit 1
  fi

  output "deploying ${CHANNEL_NAME}.xml to ${URL_N_PORT}"
  RESULT=$(curl --silent --insecure --request POST "https://${URL_N_PORT}/api/channels" \
    --header "Content-Type: application/xml" \
    --data @${CHANNEL_NAME}.xml \
    --user admin:admin | jq '.boolean')
  if [[ "${RESULT}" == 'true' ]]; then
    output "deployed successfully"
  else
    output "deployed with error"
  fi

  rm ${CHANNEL_NAME}.xml
}


# ---------- main execution ----------------------------------------------------------------------

# check if inside docker container
if [ -f /proc/1/cgroup ]; then
  # inside docker
  MIRTH_URL='mirth_app:8443'
  IE_URL='openemr_ie:8443'
else
  # not inside docker
  MIRTH_URL='127.0.0.1:8443'
  IE_URL='127.0.0.1:8444'
fi

# mirth_app is running on docker container port 8443 / host port 8443
deploy_channel ${MIRTH_URL} 'appointments-emr2twlo'

deploy_channel ${MIRTH_URL} 'appointments-twlo2emr'

curl --silent --insecure --request POST "https://${MIRTH_URL}/api/channels/_deploy" --user admin:admin
output "deployed channels on ${MIRTH_URL} ..."


# openemr_ie is running on docker container port 8443 / host port 8444
deploy_channel ${IE_URL} 'appointments-outbound'

deploy_channel ${IE_URL} 'appointments-inbound'

curl --silent --insecure --request POST "https://${IE_URL}/api/channels/_deploy" --user admin:admin
output "deployed channels on ${IE_URL} ..."


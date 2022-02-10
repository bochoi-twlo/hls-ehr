#!/bin/zsh
set -e

S3BUCKET_ARTIFACTS='twlo-hls-artifacts'

if [[ -z ${TWILIO_ACCOUNT_SID} ]]; then echo 'TWILIO_ACCOUNT_SID unset!'; exit 1; fi
if [[ -z ${TWILIO_AUTH_TOKEN} ]];  then echo 'TWILIO_AUTH_TOKEN unset!'; exit 1; fi

FLOW_SID=$(curl https://studio.twilio.com/v2/Flows \
  --silent --user ${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN} \
  | jq --raw-output '.flows[] | select(.friendly_name | contains("'appointments'")) | .sid')

FLOW_PHONE_NUMBER=$(curl https://preview.twilio.com/Numbers/ActiveNumbers \
  --silent --user ${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN} \
  | jq --raw-output '.items[] | select(.configurations.sms.url | contains("'${FLOW_SID}'")) | .phone_number')

# --------------------------------------------------------------------------------
#
# --------------------------------------------------------------------------------
function package_channel {
  URL_N_PORT=${1}
  CHANNEL_NAME=${2}

  CHANNEL_ID=$(curl --silent --insecure "https://${URL_N_PORT}/api/channels" --user admin:admin \
    | xq --raw-output '.list.channel[] | select(.name | contains("'${CHANNEL_NAME}'")) | .id')

  echo
  echo "packaging channel: CHANNEL_NAME=${CHANNEL_NAME}, CHANNEL_ID=${CHANNEL_ID}"

  if [[ "${CHANNEL_NAME}" == 'appointments-emr2twlo' ]]; then
    echo ". replace ${TWILIO_ACCOUNT_SID} with YOUR_TWILIO_ACCOUNT_SID"
    echo ". replace ${TWILIO_AUTH_TOKEN} with YOUR_TWILIO_AUTH_TOKEN"
    echo ". replace ${FLOW_SID} with YOUR_FLOW_SID"
    echo ". replace ${FLOW_PHONE_NUMBER} with YOUR_FLOW_PHONE_NUMBER"

    curl --silent --insecure --request GET "https://${URL_N_PORT}/api/channels?channelId=${CHANNEL_ID}" \
      --user admin:admin \
      | xq --xml-output .list \
      | sed "s/${TWILIO_ACCOUNT_SID}/YOUR_TWILIO_ACCOUNT_SID/" \
      | sed "s/${TWILIO_AUTH_TOKEN}/YOUR_TWILIO_AUTH_TOKEN/" \
      | sed "s/${FLOW_SID}/YOUR_FLOW_SID/" \
      | sed "s/${FLOW_PHONE_NUMBER}/YOUR_FLOW_PHONE_NUMBER/" \
      > ${CHANNEL_NAME}.template.xml
  else
    curl --silent --insecure --request GET "https://${URL_N_PORT}/api/channels?channelId=${CHANNEL_ID}" \
      --user admin:admin \
      | xq --xml-output .list \
      > ${CHANNEL_NAME}.template.xml
  fi

  aws s3 cp ${CHANNEL_NAME}.template.xml s3://${S3BUCKET_ARTIFACTS}/appointments/${CHANNEL_NAME}.template.xml --sse

  rm ${CHANNEL_NAME}.template.xml
  echo
}

package_channel '127.0.0.1:8443' 'appointments-emr2twlo'

package_channel '127.0.0.1:8443' 'appointments-twlo2emr'

package_channel '127.0.0.1:8444' 'appointments-inbound'

package_channel '127.0.0.1:8444' 'appointments-outbound'

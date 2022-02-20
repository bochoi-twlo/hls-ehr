#!/bin/zsh
set -e

S3BUCKET_ARTIFACTS='twlo-hls-artifacts'

if [[ -z ${TWILIO_ACCOUNT_SID} ]]; then echo 'TWILIO_ACCOUNT_SID unset!'; exit 1; fi
if [[ -z ${TWILIO_AUTH_TOKEN} ]];  then echo 'TWILIO_AUTH_TOKEN unset!'; exit 1; fi

FLOW_SID=$(curl https://studio.twilio.com/v2/Flows \
  --silent --user ${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN} \
  | jq --raw-output '.flows[] | select(.friendly_name | contains("'appointments'")) | .sid')
if [[ -z ${FLOW_SID} ]]; then echo "sid not found for flows[].friendly_name=appointments!"; exit 1; fi

FLOW_PHONE_NUMBER=$(curl https://preview.twilio.com/Numbers/ActiveNumbers \
  --silent --user ${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN} \
  | jq --raw-output '.items[] | select(.configurations.sms.url | contains("'${FLOW_SID}'")) | .phone_number')
if [[ -z ${FLOW_PHONE_NUMBER} ]]; then echo "phone_number not found for flow_sid=${FLOW_SID}!"; exit 1; fi

# --------------------------------------------------------------------------------
#
# --------------------------------------------------------------------------------
function deploy_channel {
  URL_N_PORT=${1}
  CHANNEL_NAME=${2}

  echo
  echo "updating channel: CHANNEL_NAME=${CHANNEL_NAME}"

  aws s3 cp s3://${S3BUCKET_ARTIFACTS}/appointments/${CHANNEL_NAME}.template.xml ${CHANNEL_NAME}.template.xml --sse

  CHANNEL_ID=$(xq --raw-output .channel.id ${CHANNEL_NAME}.template.xml)

  echo -n ". deleting CHANNEL_ID=${CHANNEL_ID} ... "
  curl --silent --insecure --request DELETE "https://${URL_N_PORT}/api/channels?channelId=${CHANNEL_ID}" \
    --user admin:admin
  [[ $? -eq 1 ]] && echo "not found" || echo "deleted"

  echo -n ". creating CHANNEL_ID=${CHANNEL_ID} ... "
  if [[ "${CHANNEL_NAME}" == 'appointments-emr2twlo' ]]; then
    echo ". replace ${TWILIO_ACCOUNT_SID} with YOUR_TWILIO_ACCOUNT_SID"
    echo ". replace ${TWILIO_AUTH_TOKEN} with YOUR_TWILIO_AUTH_TOKEN"
    echo ". replace ${FLOW_SID} with YOUR_FLOW_SID"
    echo ". replace ${PHONE_NUMBER} with YOUR_FLOW_PHONE_NUMBER"

    cat ${CHANNEL_NAME}.template.xml \
      | sed "s/YOUR_TWILIO_ACCOUNT_SID/${TWILIO_ACCOUNT_SID}/" \
      | sed "s/YOUR_TWILIO_AUTH_TOKEN/${TWILIO_AUTH_TOKEN}/" \
      | sed "s/YOUR_FLOW_SID/${FLOW_SID}/" \
      | sed "s/YOUR_FLOW_PHONE_NUMBER/${FLOW_PHONE_NUMBER}/" \
      > ${CHANNEL_NAME}.xml
  else
    cat ${CHANNEL_NAME}.template.xml > ${CHANNEL_NAME}.xml
  fi
  [[ $? -eq 0 ]] && echo "created" || exit 1

  curl --silent --insecure --request POST "https://${URL_N_PORT}/api/channels" \
    --header "Content-Type: application/xml" \
    --data @${CHANNEL_NAME}.xml \
    --user admin:admin

  rm ${CHANNEL_NAME}.xml
  echo
}


deploy_channel '127.0.0.1:8443' 'appointments-emr2twlo'

deploy_channel '127.0.0.1:8443' 'appointments-twlo2emr'

echo -n "deploying channels on 127.0.0.1:8443 ..."
curl --silent --insecure --request POST "https://127.0.0.1:8443/api/channels/_deploy" --user admin:admin
echo "done"

deploy_channel '127.0.0.1:8444' 'appointments-outbound'

deploy_channel '127.0.0.1:8444' 'appointments-inbound'

echo -n "deploying channels on 127.0.0.1:8444 ..."
curl --silent --insecure --request POST "https://127.0.0.1:8444/api/channels/_deploy" --user admin:admin
echo "done"


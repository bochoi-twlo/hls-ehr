/* ----------------------------------------------------------------------------------------------------
 * common helper function used for openemr api access
 * ----------------------------------------------------------------------------------------------------
 */

/* ----------------------------------------------------------------------------------------------------
 * obtain access_token for openEMR API client
 *
 * 1. looks for sync document uniqueName=SAVED_TOKEN_NAME
 * 2. if not exists, create new access token
 * 3. if exists, refresh access token. (this will ensure subsequent API access using active token
 * ----------------------------------------------------------------------------------------------------
 */
const assert = require("assert");
const fetch = require("node-fetch");

const SAVED_TOKEN_NAME = 'openemr_access_token';

async function getAccessToken(context, openemr_endpoint, openemr_client_id, sync_sid) {

  assert(context, 'missing context parameter context!!!');
  assert(openemr_endpoint , 'undefined parameter openemr_endpoint!!!');
  assert(openemr_client_id, 'undefined parameter openemr_client_id!!!');
  assert(sync_sid         , 'undefined parameter sync_sid!!!');

  const client = context.getTwilioClient();
  // ---------- retrieve access token stored in sync
  const documents = await client.sync.services(sync_sid).documents.list();
  let document = documents.find(d => d.uniqueName === SAVED_TOKEN_NAME);

  const isExpired = document ? new Date() > document.dateExpires : true;

  if (! document || isExpired) {
    // ---------- create new access_token
    const params = new URLSearchParams();
    params.append('client_id', openemr_client_id);
    params.append('grant_type', 'password');
    params.append('user_role', 'users');
    params.append('username', 'admin');
    params.append('password', 'pass');
    params.append('scope', 'openid offline_access api:oemr api:fhir api:port user/allergy.read user/allergy.write user/appointment.read user/appointment.write user/dental_issue.read user/dental_issue.write user/document.read user/document.write user/drug.read user/encounter.read user/encounter.write user/facility.read user/facility.write user/immunization.read user/insurance.read user/insurance.write user/insurance_company.read user/insurance_company.write user/insurance_type.read user/list.read user/medical_problem.read user/medical_problem.write user/medication.read user/medication.write user/message.write user/patient.read user/patient.write user/practitioner.read user/practitioner.write user/prescription.read user/procedure.read user/soap_note.read user/soap_note.write user/surgery.read user/surgery.write user/vital.read user/vital.write user/AllergyIntolerance.read user/CareTeam.read user/Condition.read user/Encounter.read user/Immunization.read user/Location.read user/Medication.read user/MedicationRequest.read user/Observation.read user/Organization.read user/Organization.write user/Patient.read user/Patient.write user/Practitioner.read user/Practitioner.write user/PractitionerRole.read user/Procedure.read patient/encounter.read patient/patient.read patient/Encounter.read patient/Patient.read');

    const response = await fetch(
      `${openemr_endpoint}/oauth2/default/token`,
      {method: 'POST', body: params },
    );
    // tokenData: { id_token, scope, token_type, expires_in, access_token, refresh_token }
    const tokenData = await response.json();

    // ---------- create sync document /w ttl
    document = await client.sync.services(sync_sid)
      .documents
      .create({
        uniqueName: SAVED_TOKEN_NAME,
        ttl: tokenData.expires_in, // set TTL to data.expires_in
        data: tokenData,
      });
  } else {
    // ---------- refresh access_token
    const params = new URLSearchParams();
    params.append('client_id', openemr_client_id);
    params.append('grant_type', 'refresh_token');
    params.append('refresh_token', document.data.refresh_token);

    const response = await fetch(
      `${openemr_endpoint}/oauth2/default/token`,
      { method: 'POST', body: params },
    );
    // tokenData: { id_token, token_type, expires_in, access_token, refresh_token }
    const tokenData = await response.json();

    // ---------- update sync document /w ttl
    document = await client.sync.services(sync_sid)
      .documents(document.sid)
      .update({
        ttl: tokenData.expires_in,
        data: tokenData,
      });
  }
  // console.log(document);
  return document.data.access_token;
}


// --------------------------------------------------------------------------------
module.exports = {
  getAccessToken,
}

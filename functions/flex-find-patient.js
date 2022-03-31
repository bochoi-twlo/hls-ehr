'use strict';
/* --------------------------------------------------------------------------------
 * find patients from openEMR matching name_given & name_family
 *
 * assumes following openEMR API endpoints
 * - native: http://localhost:80/apis/default/api/
 * - FHIR  : http://localhost:80/apis/default/fhir/
 *
 * NOTE: that this function can only be run on localhost
 *
 * input:
 *   name_given
 *   name_family
 *
 * return:
 *   json object containing all information needed in flex plugin;
 *   if no matching patient, returns default information (i.e., Mary Ann Doe)
 * --------------------------------------------------------------------------------
 */
const fetch = require("node-fetch");
exports.handler = async function (context, event, callback) {
  const THIS = 'flex-find-patient:';

  const assert = require("assert");
  const { getParam } = require(Runtime.getFunctions()['helpers'].path);
  const { getAccessToken } = require(Runtime.getFunctions()['helpers-openemr'].path);

  assert(context.DOMAIN_NAME.startsWith('localhost:'), `Can only run on localhost!!!`);
  assert(event.name_given , 'missing event.name_given!!!');
  assert(event.name_family, 'missing event.name_family!!!');

  console.time(THIS);
  try {

    const openemr_endpoint    = await getParam(context, 'OPENEMR_ENDPOINT');
    const openemr_client_id   = await getParam(context, 'OPENEMR_CLIENT_ID');
    const sync_sid            = await getParam(context, 'SYNC_SID');

    const openemr_access_token = await getAccessToken(context, openemr_endpoint, openemr_client_id, sync_sid);

    const patient_name_given  = event.name_given;
    const patient_name_family = event.name_family;

    const patient_info = await flex_find_patient(
      openemr_endpoint,
      openemr_client_id,
      openemr_access_token,
      patient_name_given,
      patient_name_family,
      );

    return callback(null, patient_info);

  } catch (err) {
    console.log(THIS, err);
    return callback(err);
  } finally {
    console.timeEnd(THIS);
  }
}


/* --------------------------------------------------------------------------------
 * searchs openEMR for patient matching name_give & name_family
 * if no match is found default HLS patient is returned
 *
 * returns FHIR patient resource
 * --------------------------------------------------------------------------------
 */
async function flex_find_patient(
  openemr_endpoint,
  openemr_client_id,
  openemr_access_token,
  patient_name_given,
  patient_name_family,
) {
  const params = new URLSearchParams();
  params.append('given', patient_name_given);
  params.append('family', patient_name_family);
  // note search will execute with OR logic

  const response = await fetch(
    `${openemr_endpoint}/apis/default/fhir/Patient?` + params,
    {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${openemr_access_token}`,
      },
    },
  );
  const data = await response.json();
  console.log(`openemr total = ${data.total}`);

  const defaultPatient = {
    id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    resourceType: 'Patient',
    name: [
      {
        use: 'official',
        family: 'Doe',
        given: [
          "Mary Ann",
        ],
      }
    ],
    telecom: [
      { system: 'phone', value: '', use: 'home' },
      { system: 'phone', value: '', use: 'work' },
      { system: 'phone', value: '111-222-3333', use: 'mobile' },
      { system: 'email', value: '', use: 'home' }
    ],
    gender: 'female',
    birthDate: '1990-01-01',
  };

  let patient = null;
  if (data.total === 0) {
    patient = defaultPatient;
  } else if (data.total === 1) {
    patient = data.entry[0].resource;
  } else {
    // multiple match on given OR famiy, so filter
    const matches = data.entry.filter(e => {
      return e.resource.name[0].family === patient_name_family && e.resource.name[0].given.includes(patient_name_given);
    });
    patient = matches.length === 0 ? defaultPatient : matches[0].resource
  }
  return patient;
}

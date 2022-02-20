'use strict';
/*
 * --------------------------------------------------------------------------------
 * checks deployment of deployables in target Twilio account.
 *
 * NOTE: that this function can only be run on localhost
 *
 * returns minimally object of one of more
 *
 * your-deployable-name: {
 *   deploy_state: DEPLOYED|NOT-DEPLOYED,
 * }
 * --------------------------------------------------------------------------------
 */
const assert = require("assert");
const { execSync } = require('child_process');
const { getParam } = require(Runtime.getFunctions()['helpers'].path);

exports.handler = async function (context, event, callback) {
  const THIS = 'check-application';

  assert(context.DOMAIN_NAME.startsWith('localhost:'), `Can only run on localhost!!!`);
  console.time(THIS);
  try {

    // ---------- check serverless ----------------------------------------
    const service_sid        = await getParam(context, 'SERVICE_SID');
    const environment_domain = service_sid ? await getParam(context, 'ENVIRONMENT_DOMAIN') : null;
    const application_url    = service_sid ? `https:/${environment_domain}/administration.html` : null;

    // ---------- check ehr ----------------------------------------
    const deployed = execSync('docker ps --all | grep openemr_app | wc -l').toString().trim() === '1';
    const running  = execSync('docker ps | grep openemr_app | wc -l').toString().trim() === '1';
    const sql = 'select MIN(pc_eventDate) as min_pc_eventDate from openemr.openemr_postcalendar_events';
    const yyyymmdd = (deployed && running)
      ? execSync(`docker exec openemr_db mysql --user=root --password=root --silent openemr --execute "${sql}"`).toString().trim()
      : null;

    const response = {
      'service': {
        deploy_state: service_sid ? 'DEPLOYED' : 'NOT-DEPLOYED',
        service_sid: service_sid,
        application_url: application_url,
      },
      'ehr': {
        deploy_state: deployed ? 'DEPLOYED' : 'NOT-DEPLOYED',
        running_status: running ? 'RUNNING' : 'EXITED',
        appointment_week: yyyymmdd,
      },
    };
    console.log(THIS, response);
    return callback(null, response);

  } catch (err) {
    console.log(THIS, err);
    return callback(err);
  } finally {
    console.timeEnd(THIS);
  }
}

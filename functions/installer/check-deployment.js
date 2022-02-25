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
    const ehr_information = {
      deploy_state: deployed ? 'DEPLOYED' : 'NOT-DEPLOYED',
      running_status: running ? 'RUNNING' : 'EXITED',
    };

    if (deployed && running) {
      let sql = 'select MIN(pc_eventDate) as min_pc_eventDate from openemr.openemr_postcalendar_events';
      let res = execSync(`docker exec openemr_db mysql --user=root --password=root --silent openemr --execute "${sql}"`);
      ehr_information.appointment_week = (deployed && running) ? res.toString().trim() : null;


      sql = "select concat(table_schema, '.', table_name)  from information_schema.tables where table_name = 'appointment_events'";
      res = execSync(`docker exec openemr_db mysql --user=root --password=root --silent openemr --execute "${sql}"`);
      ehr_information.event_tables = res.toString().trim();

      sql = "select trigger_name from information_schema.triggers";
      res = execSync(`docker exec openemr_db mysql --user=root --password=root --silent openemr --execute "${sql}"`).toString().replace();
      ehr_information.triggers = res.toString().trim().split('\n');

      try {
        res = execSync(`docker exec mirth_app curl --silent --insecure --request GET https://mirth_app:8443/api/channels --user admin:admin`);
        res = execSync(`docker exec mirth_app curl --silent --insecure --request GET https://mirth_app:8443/api/channels --user admin:admin | xq --raw-output '[ .list.channel | if type=="array" then . else [.] end | .[] | { name: .name, id: .id } ]'`);
        ehr_information.mirth_channels = JSON.parse(res.toString().trim());
      } catch (err) {
        ehr_information.mirth_channels = [];
      }

      try {
        res = execSync(`docker exec openemr_ie curl --silent --insecure --request GET https://openemr_ie:8443/api/channels --user admin:admin`);
        res = execSync(`docker exec openemr_ie curl --silent --insecure --request GET https://openemr_ie:8443/api/channels --user admin:admin | xq --raw-output '[ .list.channel | if type=="array" then . else [.] end | .[] | { name: .name, id: .id } ]'`);
        ehr_information.ie_channels = JSON.parse(res.toString().trim());
      } catch (err) {
        ehr_information.ie_channels = [];
      }
    }

    const response = {
      'service': {
        deploy_state: service_sid ? 'DEPLOYED' : 'NOT-DEPLOYED',
        service_sid: service_sid,
        application_url: application_url,
      },
      'ehr': ehr_information,
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

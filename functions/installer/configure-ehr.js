'use strict';
/* --------------------------------------------------------------------------------
 * deploys application (service) to target Twilio account.
 *
 * NOTE: that this function can only be run on localhost
 *
 * input:
 * event.action: CREATE|DELETE, defaults to CREATE
 * --------------------------------------------------------------------------------
 */
const assert = require("assert");
const path = require('path')
const { execSync } = require('child_process');
const { getParam } = require(Runtime.getFunctions()['helpers'].path);


exports.handler = async function(context, event, callback) {
  const THIS = 'configure-ehr';

  assert(context.DOMAIN_NAME.startsWith('localhost:'), `Can only run on localhost!!!`);
  console.time(THIS);
  try {
    const deployed = execSync("docker ps --all | grep openemr_app | wc -l");
    if (deployed.toString().trim() === '0') throw new Error('HLS-EHR not deployed!!!');

    const available_actions = [
      'ADJUST_APPOINTMENT_DATES',
      'CLEAR_APPOINTMENT_EVENTS',
    ];
    assert(event.action, `Missing event.action. valid: ${available_actions}!!!`);
    const action = event.action;

    switch (action) {

      case 'ADJUST_APPOINTMENT_DATES': {
        console.log(THIS, `adjusting appointment dates to this week ... `);

        const fp = Runtime.getAssets()['/ehr/openemr-adjust-appointment-dates.sh'].path;
        execSync(fp, { shell: '/bin/bash', cwd: path.dirname(fp), stdio: 'inherit'});

        console.log(THIS, `completed adjusting appointment dates`);
      }
      break;

      default:
        throw new Error(`unknown event.action=${action} not in ${available_actions}`);
    }

    const response = {
      status  : 'COMPLETE',
    }
    console.log(THIS, response);
    return callback(null, response);

  } catch(err) {
    console.log(err);
    return callback(err);
  } finally {
    console.timeEnd(THIS);
  }
}

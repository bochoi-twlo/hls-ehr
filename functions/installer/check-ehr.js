'use strict';
/*
 * --------------------------------------------------------------------------------
 * checks deployment of ehr in target Twilio account.
 *
 * NOTE: that this function can only be run on localhost
 * --------------------------------------------------------------------------------
 */
const assert = require('assert');
const { execSync } = require('child_process');
const { getParam } = require(Runtime.getFunctions()['helpers'].path);

exports.handler = await async function (context, event, callback) {
  const THIS = 'check-ehr';

  assert(context.DOMAIN_NAME.startsWith('localhost:'), `Can only run on localhost!!!`);
  console.time(THIS);
  try {

    const deployed = execSync("docker ps --all | grep openemr_app | wc -l");
    const running  = execSync("docker ps | grep openemr_app | wc -l");

    const response = {
      deploy_state  : deployed.toString().trim() === '1' ? 'DEPLOYED' : 'NOT-DEPLOYED',
      running_status: running.toString().trim() === '1' ? "RUNNING" : "EXITED"
    }
    console.log(THIS, response);
    return callback(null, response);

  } catch (err) {
    console.log(THIS, err);
    return callback(err);
  } finally {
    console.timeEnd(THIS);
  }
}

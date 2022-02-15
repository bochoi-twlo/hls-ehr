'use strict';
/*
 * --------------------------------------------------------------------------------
 * checks deployment of application (service) in target Twilio account.
 *
 * NOTE: that this function can only be run on localhost
 *
 * service identified via unique_name = APPLICATION_NAME in helpers.private.js
 * --------------------------------------------------------------------------------
 */
const assert = require("assert");
const { getParam } = require(Runtime.getFunctions()['helpers'].path);

exports.handler = async function (context, event, callback) {
  const THIS = 'check-application';

  assert(context.DOMAIN_NAME.startsWith('localhost:'), `Can only run on localhost!!!`);
  console.time(THIS);
  try {

    const service_sid        = await getParam(context, 'SERVICE_SID');
    const environment_domain = service_sid ? await getParam(context, 'ENVIRONMENT_DOMAIN') : null;
    const application_url    = service_sid
      ? `https:/${environment_domain}/administration.html`
      : `../administration.html`; // relative url when on localhost and service is not yet deployed

    const response = {
      deploy_state   : service_sid ? 'DEPLOYED' : 'NOT-DEPLOYED',
      service_sid    : service_sid ? service_sid : '',
      application_url: service_sid ? application_url : '',
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

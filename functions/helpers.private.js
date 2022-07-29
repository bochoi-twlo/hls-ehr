/* --------------------------------------------------------------------------------
 * common helper function used by functions
 * --------------------------------------------------------------------------------
 */
const assert = require("assert");

/* --------------------------------------------------------------------------------
 * is executing on localhost
 * --------------------------------------------------------------------------------
 */
function isLocalhost(context) {
  return context.DOMAIN_NAME.startsWith('localhost:');
}

/* --------------------------------------------------------------------------------
 * assert executing on localhost
 * --------------------------------------------------------------------------------
 */
function assertLocalhost(context) {
  assert(context.DOMAIN_NAME.startsWith('localhost:'), `Can only run on localhost!!!`);
  assert(process.env.ACCOUNT_SID, 'ACCOUNT_SID not set in localhost environment!!!');
  assert(process.env.AUTH_TOKEN, 'AUTH_TOKEN not set in localhost environment!!!');
}


/* --------------------------------------------------------------------------------
 * retrieve environment variable value
 *
 * parameters:
 * - context: Twilio Runtime context
 *
 * returns
 * - value of specified environment variable. Note that SERVICE_SID & ENVIRONMENT_SID will return 'null' if not yet deployed
 * --------------------------------------------------------------------------------
 */
async function getParam(context, key) {
  assert(context.APPLICATION_NAME, 'undefined .env environment variable APPLICATION_NAME!!!');
  assert(context.CUSTOMER_NAME, 'undefined .env environment variable CUSTOMER_NAME!!!');

  if (key !== 'SERVICE_SID' // avoid warning
    && key !== 'ENVIRONMENT_SID' // avoid warning
    && context[key]) {
    return context[key]; // first return context non-null context value
  }

  const client = context.getTwilioClient();
  switch (key) {

    case 'SERVICE_SID': // always required
    {
      const services = await client.serverless.services.list();
      const service = services.find(s => s.friendlyName === context.APPLICATION_NAME);

      // return sid only if deployed; otherwise null
      return service ? service.sid : null;
    }

    case 'APPLICATION_VERSION':
    {
      const service_sid = await getParam(context, 'SERVICE_SID');
      if (service_sid === null) return null; // service not yet deployed, therefore return 'null'

      const environment_sid = await getParam(context, 'ENVIRONMENT_SID');
      const variables = await client.serverless
        .services(service_sid)
        .environments(environment_sid)
        .variables.list();
      const variable = variables.find(v => v.key === 'APPLICATION_VERSION');

      return variable ? variable.value : null;
    }

    case 'ENVIRONMENT_SID': // always required
    {
      const service_sid = await getParam(context, 'SERVICE_SID');
      if (service_sid === null) return null; // service not yet deployed

      const environments = await client.serverless
        .services(service_sid)
        .environments.list({limit : 1});

      return environments.length > 0 ? environments[0].sid : null;
    }

    case 'ENVIRONMENT_DOMAIN': // always required
    {
      const service_sid = await getParam(context, 'SERVICE_SID');
      if (service_sid === null) return null; // service not yet deployed

      const environments = await client.serverless
        .services(service_sid)
        .environments.list({limit : 1});

      return environments.length > 0 ? environments[0].domainName: null;
    }

    case 'SYNC_SID':
    {
      const services = await client.sync.services.list();
      let service = services.find(s => s.friendlyName === context.APPLICATION_NAME);
      if (! service) {
        console.log(`Sync service not found so creating a new sync service friendlyName=${context.APPLICATION_NAME}`);
        service = await client.sync.services.create({ friendlyName: context.APPLICATION_NAME });
      }
      if (! service) throw new Error('Unable to create a Twilio Sync Service!!! ABORTING!!!');

      await setParam(context, key, service.sid);
      return service.sid;
    }

    case 'VERIFY_SID':
    {
      const services = await client.verify.services.list();
      let service = services.find(s => s.friendlyName === context.APPLICATION_NAME);
      if (! service) {
        console.log(`Verify service not found so creating a new verify service friendlyName=${context.APPLICATION_NAME}`);
        service = await client.verify.services.create({ friendlyName: context.APPLICATION_NAME });
      }
      if (! service) throw new Error('Unable to create a Twilio Verify Service!!! ABORTING!!!');

      await setParam(context, key, service.sid);
      return service.sid;
    }

    default:
      throw new Error(`Undefined key: ${key}!!!`);
  }
}


/* --------------------------------------------------------------------------------
 * deprovision environment variable
 * --------------------------------------------------------------------------------
 */
async function provisionParams(context) {
  const client = context.getTwilioClient();

  return {
    'SYNC_SID': await getParam(context, 'SYNC_SID'),
    'VERIFY_SID': await getParam(context, 'VERIFY_SID'),
  }
}


/* --------------------------------------------------------------------------------
 * deprovision environment variable
 * --------------------------------------------------------------------------------
 */
async function deprovisionParams(context) {
  const client = context.getTwilioClient();

  const resources = {};

  const sync_id = await getParam(context, 'SYNC_SID');
  if (sync_id) {
    let sync_service = null;
    try {
      sync_service = await client.sync.services(sync_id).fetch();
      if (sync_service) {
        await client.sync.services(sync_id).remove();
        resources['SYNC_SID'] = sync_id;
      }
    } catch (err) {
      console.log(`no sync service SID=${sync_id}. skpping...`);
    }
  }

  const verify_sid = await getParam(context, 'VERIFY_SID');
  if (verify_sid) {
    let verify_service = null;
    try {
      verify_service = await client.verify.services(verify_sid).fetch();
      if (verify_service) {
        await client.verify.services(verify_sid).remove();
        resources['VERIFY_SID'] = verify_sid;
      }
    } catch (err) {
      console.log(`no verify service SID=${verify_sid}. skpping...`);
    }
  }

  return resources;
}


/* --------------------------------------------------------------------------------
 * sets environment variable on deployed service, does nothing on localhost
 * --------------------------------------------------------------------------------
 */
async function setParam(context, key, value) {
  const service_sid = await getParam(context, 'SERVICE_SID');
  if (! service_sid) return null; // do nothing is service is not deployed

  const client = context.getTwilioClient();

  const environment_sid = await getParam(context, 'ENVIRONMENT_SID');
  const variables = await client.serverless
    .services(service_sid)
    .environments(environment_sid)
    .variables.list();
  let variable = variables.find(v => v.key === key);

  if (variable) {
    // update existing variable
    await client.serverless
      .services(service_sid)
      .environments(environment_sid)
      .variables(variable.sid)
      .update({ value })
      .then((v) => console.log('setParam: updated variable', v.key));
  } else {
    // create new variable
    await client.serverless
      .services(service_sid)
      .environments(environment_sid)
      .variables.create({ key, value })
      .then((v) => console.log('setParam: created variable', v.key));
  }
  return {
    key: key,
    value: value
  };
}


/* --------------------------------------------------------------------------------
 * read version attribute from package.json
 * --------------------------------------------------------------------------------
 */
async function fetchVersionToDeploy() {
  const fs = require('fs');
  const path = require('path');

  const fpath = path.join(process.cwd(), 'package.json');
  const payload = fs.readFileSync(fpath, 'utf8');
  const json = JSON.parse(payload);

  return json.version;
}


// --------------------------------------------------------------------------------
module.exports = {
  getParam,
  setParam,
  fetchVersionToDeploy,
  provisionParams,
  deprovisionParams,
  isLocalhost,
  assertLocalhost,
}

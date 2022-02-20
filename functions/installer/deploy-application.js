'use strict';
/* --------------------------------------------------------------------------------
 * deploys application (service) to target Twilio account.
 *
 * NOTE: that this function can only be run on localhost
 *
 * input:
 * event.action: CREATE|UPDATE|DELETE, defaults to CREATE|UPDATE depending on deployed state
 *
 * service identified via unique_name = APPLICATION_NAME in helpers.private.js
 * --------------------------------------------------------------------------------
 */
const assert = require("assert");
const { getParam, getAllParams } = require(Runtime.getFunctions()['helpers'].path);
const { TwilioServerlessApiClient } = require('@twilio-labs/serverless-api');
const { getListOfFunctionsAndAssets } = require('@twilio-labs/serverless-api/dist/utils/fs');
const fs = require('fs');


exports.handler = async function(context, event, callback) {
  const THIS = 'deploy-application';

  assert(context.DOMAIN_NAME.startsWith('localhost:'), `Can only run on localhost!!!`);
  console.time(THIS);
  try {
    assert(event.configuration.APPLICATION_NAME, 'missing APPLICATION_NAME variable!!!');
    const application_name = event.configuration.APPLICATION_NAME;

    console.log(THIS, `Deploying Twilio service ... ${application_name}`);
    const environmentVariables = event.configuration;
    console.log(THIS, 'configuration:', environmentVariables);

    const service_sid = await deployService(context, environmentVariables);
    console.log(THIS, `Deployed: ${service_sid}`);

    console.log(THIS, 'Make Twilio service editable ...');
    const client = context.getTwilioClient();
    await client.serverless
      .services(service_sid)
      .update({ uiEditable: true });

    console.log(THIS, 'Provisioning dependent Twilio services');
    const params = await getAllParams(context);
    //console.log(THIS, params);

    console.log(THIS, `Completed deployment of ${application_name}`);

    return callback(null, {
      service_sid: service_sid,
      service_status: 'DEPLOYED',
    });

  } catch(err) {
    console.log(err);
    return callback(err);
  } finally {
    console.timeEnd(THIS);
  }
}

/* --------------------------------------------------------------------------------
 * deploys (creates new/updates existing) service to target Twilio account.
 *
 * - service identified via unique_name = APPLICATION_NAME in helpers.private.js
 *
 * returns: service SID, if successful
 * --------------------------------------------------------------------------------
 */
async function getAssets() {
  const { assets } = await getListOfFunctionsAndAssets(process.cwd(), {
    functionsFolderNames: [],
    assetsFolderNames: ["assets"],
  });
  //console.log('asset count:', assets.length);

  const indexHTMLs = assets.filter(asset => asset.name.includes('index.html'));
  // Set indext.html as a default document
  const allAssets = assets.concat(indexHTMLs.map(ih => ({
    ...ih,
    path: ih.name.replace("index.html", ""),
    name: ih.name.replace("index.html", ""),
  })));
  //console.log(allAssets);
  return allAssets;
}

async function deployService(context, envrionmentVariables = {}) {
  const client = context.getTwilioClient();

  const assets = await getAssets();
  console.log('asset count:' , assets.length);

  const { functions } = await getListOfFunctionsAndAssets(process.cwd(),{
    functionsFolderNames: ["functions"],
    assetsFolderNames: []
  });
  console.log('function count:' , functions.length);

  const pkgJsonRaw = fs.readFileSync(`${process.cwd()}/package.json`);
  const pkgJsonInfo = JSON.parse(pkgJsonRaw);
  const dependencies = pkgJsonInfo.dependencies;
  console.log('package.json loaded');

  const deployOptions = {
    env: {
      ...envrionmentVariables
    },
    pkgJson: {
      dependencies,
    },
    functionsEnv: 'dev',
    functions,
    assets,
  };
  console.log('deployOptions.env:', deployOptions.env);

  context['APPLICATION_NAME'] = envrionmentVariables.APPLICATION_NAME;
  let service_sid = await getParam(context, 'SERVICE_SID');
  if (service_sid) {
    // update service
    console.log('updating services ...');
    deployOptions.serviceSid = service_sid;
  } else {
    // create service
    console.log('creating services ...');
    deployOptions.serviceName = await getParam(context, 'APPLICATION_NAME');
  }

  const serverlessClient = new TwilioServerlessApiClient({
    username: client.username, // ACCOUNT_SID
    password: client.password, // AUTH_TOKEN
  });

  serverlessClient.on("status-update", evt => {
    console.log(evt.message);
  });

  await serverlessClient.deployProject(deployOptions);
  service_sid = await getParam(context, 'SERVICE_SID');

  return service_sid;
}

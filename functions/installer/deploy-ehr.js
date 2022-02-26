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
  const THIS = 'deploy-ehr';

  assert(context.DOMAIN_NAME.startsWith('localhost:'), `Can only run on localhost!!!`);
  console.time(THIS);
  try {
    // when installer is run locally (and not via Docker),
    // using 'docker-compose' command on Mac, execSync does not work properly over sym links
    // and requires a PATH to the executable for docker-compose v1 directly
    // there, the following MAC_PATH needs to added to the PATH environment for execSync
    const MAC_PATH=':/Applications/Docker.app/Contents/Resources/bin/docker-compose-v1:/Applications/Docker.app/Contents/Resources/bin';
    assert (process.env.PATH, 'Must start twilio serverless:start with --load-local-env option!!!');
    console.log(THIS, `path = ${process.env.PATH + MAC_PATH}`);

    const action = event.action ? event.action : 'CREATE';

    switch (action) {

      case 'DELETE': {
        const deployed = execSync("docker ps --all | grep openemr_app | wc -l");
        if (deployed.toString().trim() != '1') throw new Error('HLS-EHR not deployed!!!');

        const fp = Runtime.getAssets()['/ehr/ehr-uninstall.sh'].path;
        execSync(fp, { env: {'PATH': process.env.PATH + MAC_PATH}, shell: '/bin/bash', stdio: 'inherit',});
      }
        break;

      case 'CREATE': {

        const deployed = execSync("docker ps --all | grep openemr_app | wc -l");
        if (deployed.toString().trim() === '1') throw new Error('HLS-EHR already deployed!!!');

        console.log(THIS, `deploying HLS-EHR ... `);

        const environmentVariables = event.configuration;
        console.log(THIS, 'configuration:', environmentVariables);

        { // create docker-compose stack
          const fp = Runtime.getAssets()['/ehr/ehr-install.sh'].path;
          execSync(fp, { shell: '/bin/bash', env: {'PATH': process.env.PATH + MAC_PATH}, stdio: 'inherit',});

          execSync("docker network connect hls-ehr_default hls-ehr-installer");
        }

        { // apply iframe fix
          const fp = Runtime.getAssets()['/ehr/openemr-fix-iframe.sh'].path;
          execSync(fp, { cwd: path.dirname(fp), shell: '/bin/bash', stdio: 'inherit',});
        }

        { // restore docker volumes
          const fp = Runtime.getAssets()['/ehr/openemr-restore-volumes.sh'].path;
          execSync(`${fp} himss`, { cwd: path.dirname(fp), shell: '/bin/bash', stdio: 'inherit',});
        }

        { // adjust appointment dates to current week
          const fp = Runtime.getAssets()['/ehr/openemr-adjust-appointment-dates.sh'].path;
          execSync(fp, { cwd: path.dirname(fp), shell: '/bin/bash', stdio: 'inherit'});
        }

        // const cmd = 'docker-compose --project-name hls-ehr stop';
        // execSync(cmd, {env: {'PATH': process.env.PATH + MAC_PATH}, stdio: 'inherit',});

        { // deploy mirth channels
          const client = context.getTwilioClient();
          let flow_sid = null;
          await client.studio.flows.list({ limit: 100 }).then((flows) =>
            flows.forEach((f) => {
              if (f.friendlyName === 'patient-appointment-management') {
                flow_sid = f.sid;
              }
            })
          );
          if (flow_sid !== null) {
            const fp = Runtime.getAssets()['/ehr/mirth-deploy-channels.sh'].path;
            execSync(fp, { cwd: path.dirname(fp), shell: '/bin/bash', stdio: 'inherit'});
          } else {
            console.log(THIS, 'patient-appointment-management studio flow not found, skipping mirth channel deployment')
          }
        }
        console.log(THIS, `HLS-EHR deployed successfully`);
      }
      break;

      default:
        throw new Error(`unknown event.action=${action}`);
    }

    const deployed = await execSync("docker ps --all | grep openemr_app | wc -l");
    const response = {
      deploy_state  : deployed.toString().trim() === '1' ? 'DEPLOYED' : 'NOT-DEPLOYED',
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

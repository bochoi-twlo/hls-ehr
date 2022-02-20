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
    const action = event.action ? event.action : 'CREATE';

    switch (action) {

      case 'CREATE': {

        const deployed = execSync("docker ps --all | grep openemr_app | wc -l");
        if (deployed.toString().trim() === '1') throw new Error('HLS-EHR already deployed!!!');

        console.log(THIS, `deploying HLS-EHR ... `);
        const environmentVariables = event.configuration;
        console.log(THIS, 'configuration:', environmentVariables);

        {
          // create docker-compose stack
          const fp = Runtime.getAssets()['/ehr/ehr-install.sh'].path;
          execSync(fp, {shell: '/bin/bash', stdio: 'inherit'});
        }

        {
          const cmd = 'docker compose --project-name hls-ehr stop';
          execSync(cmd, {stdio: 'inherit'});
        }

        {        // apply iframe fix
          const fp = Runtime.getAssets()['/ehr/openemr-fix-iframe.sh'].path;
          execSync(fp, {cwd: path.dirname(fp), shell: '/bin/bash', stdio: 'inherit'});
        }

        {        // restore docker volumes
          const fp = Runtime.getAssets()['/ehr/openemr-restore-volumes.sh'].path;
          execSync(fp, {cwd: path.dirname(fp), shell: '/bin/bash', stdio: 'inherit'});
        }

        {
          const cmd = 'docker compose --project-name hls-ehr start';
          execSync(cmd, {stdio: 'inherit'});
        }
        console.log(THIS, `HLS-EHR deployed successfully`);
      }
      break;

      case 'DELETE': {
        const deployed = execSync("docker ps --all | grep openemr_app | wc -l");
        if (deployed.toString().trim() != '1') throw new Error('HLS-EHR not deployed!!!');

        const fp = Runtime.getAssets()['/ehr/ehr-uninstall.sh'].path;
        execSync(fp, { shell: '/bin/bash', stdio: 'inherit' });
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

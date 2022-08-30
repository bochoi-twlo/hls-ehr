# HLS EHR (Electronic Health Record)

Documentation for installation & using HLS-EHR comprised of openEMR & Mirth Connect
deployed using docker compose (see [docker-compose.yml](https://github.com/bochoi-twlo/hls-ehr/blob/main/docker-compose.yml)).

- [User Guide](#user-guide)
- [Installation on Localhost](#installation-on-localhost)
- [Developer Notes](#developer-notes)


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
# User Guide


## Open directly

Either click the link `Open EHR` in the installer
that will open `http://localhost:80/interface/login/login.php?site=default`
and login using the credentials `admin/pass`

Note that if you had previously access openEMR
, some client javascript file may be cached in your browser.
Please clear you cached files.

## Open inside Twilio Flex Agent Desktop

OpenEMR can be embedded in the Twilio Flex agent desktop via `iframe`.

Launch chrome via cli.
```shell
open -na Google\ Chrome --args --user-data-dir=/tmp/temporary-chrome-profile-dir --disable-web-security --disable-site-isolation-trials
```
For windows command go [here](https://stackoverflow.com/questions/3102819/disable-same-origin-policy-in-chrome)


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
# Installation on Localhost

If you wish to run HLS-EHR (OpenEMR) locally to have your private instance,
please follow the instructions in this section.

Alternatively, you can use the shared HLS-EHR instance available in AWS.

--------------------------------------------------------------------------------
## Prerequisite

The following prerequisites must be satisfied prior to installing the application.

### Provision Twilio Account
You will need the following Twilio assets ready prior to installation:
- **Twilio account**
  - Create a Twilio account by signing up [here](https://www.twilio.com/try-twilio).
  - *(You will use your login information to get started with the Quick Deploy installation on the app's CodeExchange page)*
- **Twilio phone number**
  - After provisioning your Twilio account, you will need to [purchase a phone number](https://www.twilio.com/console/phone-numbers/incoming) to use in the application.
  - Make sure the phone number is SMS enabled
  - *(This will be the number patients receive texts from)*


### Docker Desktop

Install Docker desktop that includes docker compose CLI will be used to run the application installer locally on your machine.
Goto [Docker Desktop](https://www.docker.com/products/docker-desktop) and install with default options.
After installation make sure to start Docker desktop.


### Allow Chrome Insecure `localhost` Connection

OpenEMR & Mirth run over the insecure http (as opposed to certificate backed https)
, we recommend that you use chrome only and allow chrome to open connections to insecure localhost.

Either manually open a new chrome tab and open -a Google\ Chrome
```
chrome://flags/#allow-insecure-localhost
```

Or, use terminal to execute: `open -a Google\ Chrome chrome://flags/#allow-insecure-localhost`

Chrome tab should open as below:
![Chrome Flags](assets/images/chrome-flag.png)

Set the option to 'Enabled' for 'Allow invalid certificate for resources loaded from localhost.'

Note that this will re-launch chrome.


### ngrok

If you will demo a blue print that will need to connect back to your macbook from the internet (e.g., "patient appointment management"), you need to install a reverse proxy.

```shell
brew install ngrok
```

If you have twilio email, register at `ngrok.com` using your twilio email.
Login to `ngrok.com` and follow step 2. to connect your `ngrok` on your laptop to your account.

```shell
ngrok authtoken your-ngrok-auth-token
```


and get yourself invited from hls team mebmer to assign a static ngrok url for yourself
(e.g., `bochoi.ngrok.io`).

Once you are registered, you can sign into https://dashboard.ngrok.com/team/members

If you need to connect to mirth from the internet,
start ngrok using your static ngrok URL on local port 8661
```shell
ngrok http --region=us --hostname=bochoi.ngrok.io 8661
```


--------------------------------------------------------------------------------
## Installation Steps


### Clean-up Previous Installation (Optional)

Installer can remove, existing installation of docker compose stack named `hls-ehr`
by clicking the [![](https://img.shields.io/badge/remove_ehr_on_localhost-blue?style=for-the-badge)]()

However, if you have previous installed openEMR using a different docker compose stack
, please remove the running docker container and image via the Docker Desktop or via command line

```shell
docker-compose --project-name your-openemr-stack-name down
```

After container and image removal, unsued volumes need to be removed via
```shell
docker volume prune --force
```

### Patient-Appointment-Management Integration (Optional)

In order to integrate with patient-appointment-management integration
, you **must** have `patient-appointment-managment` blueprint deployed in your target twilio account
so that the HLS-EHR installer can detect it.

After HLS-EHR installation, integration will work immediately.

Remember that after HLS-EHR installation, `ngrok` will need to running in order to receive 2-way SMS.


### Remove Docker Image

First, to ensure installation using the latest docker image, execute the following in your terminal window

```shell
docker image rm twiliohls/hls-ehr-installer
```

If running on Apple Silicon (M1 chip), add `--platform linux/amd64` option.


### Run Installer Docker Container

Please ensure that you do not have any running processes that is listening on port 3000
such development servers or another HLS docker installer still running.

Replace `${TWILIO_ACCOUNT_SID}` and `${TWILIO_AUTH_TOKEN}` with that of your target Twilio account.
Alternatively, have environment variable set in your terminal.

```shell
docker run --name hls-ehr-installer --rm --publish 3000:3000  \
--volume /var/run/docker.sock:/var/run/docker.sock \
--env ACCOUNT_SID=${TWILIO_ACCOUNT_SID} --env AUTH_TOKEN=${TWILIO_AUTH_TOKEN} \
--interactive --tty twiliohls/hls-ehr-installer
```

If running on Apple Silicon (M1 chip), add `--platform linux/amd64` option.


### Open installer in browser

Open http://localhost:3000/installer/index.html

Fill in all required environment variables and/or change them to meet your needs.

Click `Deploy` to install the application to your Twilio account
and wait until installer indicates completion.

You can uninstall too if 'Remove ...' button is displayed and active. This will completely remove your installation.


### Terminate installer

To terminate installer:
- Enter Control-C in the terminal where `docker run ...` was executed
- Stop the `hls-ehr-installer` docker container via the Docker Desktop



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
# Developer Notes

- [Installation on AWS](#installation-on-aws)
- [Mirth Connect Administrator](#mirth-connect-administrator)
- [Enabling Native & FHIR API](#enabling-native--fhir-api)
- [TBD](#)
- [Archive](#archive)


--------------------------------------------------------------------------------
## Installation on AWS

Instructions to install HLS-EHR in AWS for shared use.
Docker engine running on EC2 instance will host HLS-EHR installation.
Endpoint will be `ehr.cloudcityhealthcare.com`.

0. [AWS Setup for HLS](#0-aws-setup-for-hls)
1. [Provision EC2 Instance](#1-provision-ec2-instance)
2. [Configure DNS](#2-configure-dns)
3. [Install Docker Engine on EC2](#3-install-docker-engine-on-ec2)
4. [Install HLS-EHR on EC2 in Docker](#4-install-hls-ehr-on-ec2-in-docker)
5. [Configure SSL on OpenEMR](#5-configure-ssl-on-openemr)


### Prerequisites

#### Access to `moneytronic` AWS Account

- login access to `moneytronic` AWS Account. Ask demo engineering.
- `hls.pem` private key file for SSH into AWS. Ask HLS engineering.
  Make sure to change file permission via `chmod 400 hls.pem`


#### Twilio Account

You will need `ACCOUNT_SID` & `AUTH_TOKEN` of a provisioned Twilio account in order to
run the installer.


### 0. AWS Setup for HLS

For new AWS accounts, the following resources need to be configured for HLS use.
Skip this step, if the resources already exist.

- VPC (`hls-vpc`) in `us-west-2` region using wizard
  - 2 public subnets: `hls-subnet-public1-us-west-2a`, `hls-subnet-public1-us-west-2b`
    - internet gateway attached to public subnets
  - 2 private subnets: `hls-subnet-private1-us-west-2a`, `hls-subnet-private2-us-west-2b`
  - Security groups
    - `hls-ehr-sg` with inbound rule: 22, 80, 443, 3000 from 0.0.0.0/0
- Route53
  - Hosted zone: `cloudcityhealthcare.com`


### 1. Provision EC2 Instance

Create EC2 instance either from Scratch or AMI


#### Create EC2 Instance from Scratch

If you wish to create EC2 instance from AMI that is pre-configured, please skip this section.

- Login into `moneytronic` AWS account at https://moneytronic.signin.aws.amazon.com/console
- Goto EC2 console at https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#Home:
- Make sure EC2 instance named `hls-ehr` doesn't already exist.
  If it does exist, please terminate the instance first
- Create new EC2 instance via clicking ![](https://img.shields.io/badge/-Launch_instance-orange).
  Keep all default and confirm/change only the following:

| Section            |Property|Value|Notes|
| ------------------------- | ----- | ---------- | ----- |
| Name and tags             | Name          |`hls-ehr`
| Application and OS Images | AMI           |`Amazon Linux 2`
| Instance type             | Instance type |`t3.large`|2vCPU & 8GB memory
| Key pair (login)          | Key pair name |`hls`
| Network settings          | Auto-asssign public IP |`Enable`
|                           | Firewall      | Select existing security group `hls-ehr-sg`
| Configure storage         |               |`25 GiB gp2`

- Launch instance


#### Create EC2 Instance from AMI

If you wish create from scatch EC2 instance, please skip this step.

TBD


#### Check EC2 Instance Creation

- Note the pubic IP of the EC2 instance
- Confirm that you can SSH into the new EC2 instance.
  Connect/SSH to instance from directory containing `hls.pem` file via command
  , where `xx.yy.zz.mm` is the public IP of EC2 instance
```shell
ssh -i hls.pem ec2-user@xx.yy.zz.mm
```


### 2. Configure DNS

- Goto Route53 console at https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones
- Select `cloudcityhealthcare.com` zone
- Set/Update `A` record for `ehr.cloudcityhealthcare.com` to the public IP of EC2 instance


### 3. Install Docker Engine on EC2

Skip this step, if EC2 instance was not created from AMI.

- SSH to EC2 instance
- Execute the following answering `y` as needed
```shell
sudo yum update -y
sudo amazon-linux-extras install docker
sudo yum install docker 
sudo service docker start 
sudo usermod -a -G docker ec2-user 
```

- Logout of EC2 instance and connect again and confirm docker installation.
  Docker version should be v20.10.17 or higher
```shell
docker --version
```

- Install docker-compose.
  Docker compose version should be v2.10.2 or higher
```shell
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version
```

Reference: https://stackoverflow.com/questions/63708035/installing-docker-compose-on-amazon-ec2-linux-2-9kb-docker-compose-file


### 4. Install HLS-EHR on EC2 in Docker

Skip this step, if EC2 instance was not created from AMI.

- SSH to EC2 instance
- In SSH terminal, start the installer following [Run Installer Docker Container](#run-installer-docker-container)
- In your laptop broswer, open http://xx.yy.zz.mm:3000/instaler/index.html
- Wait for page to load and then click ![](https://img.shields.io/badge/-Deploy_EHR-blue)
- Wait for installation to finish, error message on Mirth is okay to ignore
- Open another terminal and SSH to EC2
- List all running processes on EC2
```shell
$ ps -a
  PID TTY          TIME CMD
 3751 pts/0    00:00:00 docker
 9539 pts/1    00:00:00 ps
```
- Note the PID of CMD `docker`
- Run `kill -9 3751` to terminate the running docker installer
- Check all docker containers running
```shell
$ docker container list
CONTAINER ID   IMAGE                                  COMMAND                  CREATED          STATUS          PORTS                                                                                                                             NAMES
61040a7167c1   nextgenhealthcare/connect:3.10.1-jdk   "/entrypoint.sh ./mc…"   10 minutes ago   Up 10 minutes   0.0.0.0:8081->8080/tcp, :::8081->8080/tcp, 0.0.0.0:8444->8443/tcp, :::8444->8443/tcp                                              openemr_ie
def3913729a5   openemr/openemr:6.0.0                  "./run_openemr.sh"       10 minutes ago   Up 8 minutes    0.0.0.0:80->80/tcp, :::80->80/tcp, 0.0.0.0:443->443/tcp, :::443->443/tcp                                                          openemr_app
434eda2b375a   nextgenhealthcare/connect:3.10.1-jdk   "/entrypoint.sh ./mc…"   10 minutes ago   Up 10 minutes   0.0.0.0:8080->8080/tcp, :::8080->8080/tcp, 0.0.0.0:8443->8443/tcp, :::8443->8443/tcp, 0.0.0.0:8661->8661/tcp, :::8661->8661/tcp   mirth_app
5dea5484815d   postgres:13.2                          "docker-entrypoint.s…"   10 minutes ago   Up 10 minutes   0.0.0.0:5433->5432/tcp, :::5433->5432/tcp                                                                                         openemr_ie_db
33394ad54f54   postgres:13.2                          "docker-entrypoint.s…"   10 minutes ago   Up 10 minutes   0.0.0.0:5432->5432/tcp, :::5432->5432/tcp                                                                                         mirth_db
2e7a2141ca26   mariadb:10.5                           "docker-entrypoint.s…"   10 minutes ago   Up 8 minutes    0.0.0.0:3306->3306/tcp, :::3306->3306/tcp                                                                                         openemr_db
daa1d9e4e419   twiliohls/hls-ehr-installer            "docker-entrypoint.s…"   13 minutes ago   Up 13 minutes   0.0.0.0:3000->3000/tcp, :::3000->3000/tcp                                                                                         hls-ehr-installer
```


### 5. Configure SSL on OpenEMR

Skip this step, if EC2 instance was not created from AMI.

- SSH to EC2 instance
- Install `git`
```shell
sudo yum install git -y
```

- Clone HLS-EHR git repo
```shell
git clone https://github.com/bochoi-twlo/hls-ehr.git
```

- Copy certificate & key files to `openemr_app` docker container
```shell
docker exec openemr_app mkdir /var/www/localhost/htdocs/openemr/ssl
docker cp hls-ehr/ssl-ehr.cloudcityhealthcare.com/Server.key openemr_app:/var/www/localhost/htdocs/openemr/ssl/Server.key
docker cp hls-ehr/ssl-ehr.cloudcityhealthcare.com/Server.crt openemr_app:/var/www/localhost/htdocs/openemr/ssl/Server.crt
docker cp hls-ehr/ssl-ehr.cloudcityhealthcare.com/CertificateAuthority.key openemr_app:/var/www/localhost/htdocs/openemr/ssl/CertificateAuthority.key
docker cp hls-ehr/ssl-ehr.cloudcityhealthcare.com/CertificateAuthority.crt openemr_app:/var/www/localhost/htdocs/openemr/ssl/CertificateAuthority.crt
```

- Replace SSL configuration on `openemr_app` docker container
```shell
docker exec openemr_app cp /etc/apache2/conf.d/openemr.conf /etc/apache2/conf.d/openemr-original.conf
docker exec openemr_app cp /etc/apache2/conf.d/ssl.conf     /etc/apache2/conf.d/ssl-original.conf
docker cp hls-ehr/ssl-ehr.cloudcityhealthcare.com/openemr.conf openemr_app:/etc/apache2/conf.d/openemr.conf
docker cp hls-ehr/ssl-ehr.cloudcityhealthcare.com/ssl.conf      openemr_app:/etc/apache2/conf.d/ssl.conf
```

- Connect to `openemr_app` docker container

```shell
docker exec -it openemr_app /bin/sh
```

- Copy



- From you laptop chrome, open https://ehr.cloudcityhealthcare.com
- The OpenEMR login page should display and you can login using `admin/pass` credentials
- Exit docker container
- Exit EC2 instance


### 6. Creating new AMI

After fully provisioning HLS-EHR starting scartch EC2 instance, you can create a new AMI.

- Login into `moneytronic` AWS account at https://moneytronic.signin.aws.amazon.com/console
- Goto EC2 console at https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#Home:
- If AMI named `hls-ehr-ami` already exists, delete it
- Select `hls-ehr` EC2 instance and choose 'Create Image' action
- TBD


--------------------------------------------------------------------------------
## Mirth Connect Administrator

Mirth Connect Administrator is used for managing/monitoring EHR integration.

### Installing MCA

- Download MCA installable (mirth-administrator-launcher-1.1.0-macos.dmg)
  - Log into HLS AWS account (757418860937)
  - Download s3://twlo-hls-artifacts/installables/mirth-administrator-launcher-1.1.0-macos.dmg to your 'Downloads' folder
- Open the dmg. **Note that simply opening the dmg will NOT install properly!!!**
- Drag out the 'Mirth Connect Administrator Launcher Installer' to local directory (~/Desktop). This will 'mount' the install app.
- Execute the following commands to install:
  -  Reference: https://forums.mirthproject.io/forum/mirth-connect/support/174768-mirth-connect-administrator-launcher-1-1-0-macosx
```shell
bochoi % sudo su -          # this will change your identity to 'root'
Password:                   # enter your Mac password
 
root % mount                # confirm that MCAL (Mirth Connect Administrator Launcher) is mounted (e.g., /dev/disk4 below)
/dev/disk3s1s1 on / (apfs, sealed, local, read-only, journaled)
devfs on /dev (devfs, local, nobrowse)
/dev/disk3s6 on /System/Volumes/VM (apfs, local, noexec, journaled, noatime, nobrowse)
/dev/disk3s2 on /System/Volumes/Preboot (apfs, local, journaled, nobrowse)
/dev/disk3s4 on /System/Volumes/Update (apfs, local, journaled, nobrowse)
/dev/disk1s2 on /System/Volumes/xarts (apfs, local, noexec, journaled, noatime, nobrowse)
/dev/disk1s1 on /System/Volumes/iSCPreboot (apfs, local, journaled, nobrowse)
/dev/disk1s3 on /System/Volumes/Hardware (apfs, local, journaled, nobrowse)
/dev/disk3s5 on /System/Volumes/Data (apfs, local, journaled, nobrowse, protect)
map auto_home on /System/Volumes/Data/home (autofs, automounted, nobrowse)
/dev/disk4 on /Volumes/Mirth Connect Administrator Launcher (hfs, local, nodev, nosuid, read-only, noowners, quarantine, mounted by bochoi)
 
root % cd "/Volumes/Mirth Connect Administrator Launcher"
 
root % ./Mirth\ Connect\ Administrator\ Launcher\ Installer.app/Contents/MacOS/JavaApplicationStub -c
This will install Mirth Connect Administrator Launcher on your computer.
OK [o, Enter], Cancel [c]
...
... you'll have to [Enter] many times
...
Run Mirth Connect Administrator Launcher?
Yes [y, Enter], No [n]
n
Finishing installation ...
 
root % exit                 # this will return your identity yourself
 
bochoi %
```

- You should see 'Mirth Connect Administrator Launcher' in your /Applications folder as below
  ![mca](assets/images/mca-in-app-folder.png)


### Launching MCA

- MCA must be launched via command line as superuser. **Your MUST keep this terminal window running after MCA starts!**
```shell
sudo su
cd "/Applications/Mirth Connect Administrator Launcher.app/Contents/MacOS"
./JavaApplicationStub
```

- Launcher initial window will display
  ![mca-launcher](assets/images/mca-launcher.png)

- If registration window comes up, just close it (error)
- Click 'Launch' button on the upper right and enter the same credentials used to log into dashboard at the login window
  ![mca-launcher](assets/images/mca-login.png)
- Verify the 'Address' that you are connecting to the correct Interface Engine
    - 8443 for the integrator mirth
    - 8444 for the openemr IE mirth

- MCA main window will display



--------------------------------------------------------------------------------
## Enabling Native & FHIR API

Source: [How to use Open EMR v6 API Password Grant Flow](https://benmarte.com/blog/openemr-api-v6/)

### API Documentation

[Swagger API Documentation](https://eleven.openemr.io/a/openemr/swagger/index.html)

Note that above link for OpenEMR 7.0 API, we are currently on OpenEMR 6.0.

OpenEMR 6.1 ships with swagger inclueded while OpenEMR 6.0 does not.


### Enable API Service in OpenEMR

- Navigate to Administration &#8594; Globals &#8594; Connectors
- Enter `http://localhost` in *'Site Address'*
- Enable *'OpenEMR Standard REST API'*
- Enable *'OpenEMR Standard FHIR REST API'*
- Enable *'OpenEMR Patient Portal REST API (EXPERIMENTAL)'*
- Enable *'OpenEMR Patient Portal FHIR REST API (EXPERIMENTAL)'*
- Enable *'OAuth2 Password Grant (Not considered secure)'* for *'On for Both Roles'*
- Scroll to bottom and click *'Save'* button
- Confirm via
  ```shell
  curl --silent --location --request GET 'http://localhost:80/apis/default/fhir/metadata' | jq .
  ```
  that will return a response of `CapabilityStatement` like below
  ```json
  {
    "resourceType": "CapabilityStatement",
    "status": "Not provided",
    "date": "2022-03-30",
    "kind": "instance",
    "software": {
      "name": "OpenEMR",
      "version": "6.0.0"
    },
    "implementation": {
      "description": "OpenEMR FHIR API",
      "url": "http://localhost/apis/default/fhir"
    },
    "fhirVersion": "4.0.1",
    "format": [
      "application/json"
    ],
    "rest": [
  ...
  ```

### Register an API Client

Register a client via:
```shell
curl -X POST -k -H 'Content-Type: application/json' -i 'http://localhost:80/oauth2/default/registration' --data '{
  "application_type": "private",
  "redirect_uris": [ "http://localhost:3000" ],
  "post_logout_redirect_uris": [ "http://localhost:3000" ],
  "initiate_login_uri": "http://localhost:3000",
  "client_name": "hls-api-client",
  "token_endpoint_auth_method": "client_secret_post",
  "username": "admin",
  "password": "pass",
  "scope": "openid offline_access api:oemr api:fhir api:port user/allergy.read user/allergy.write user/appointment.read user/appointment.write user/dental_issue.read user/dental_issue.write user/document.read user/document.write user/drug.read user/encounter.read user/encounter.write user/facility.read user/facility.write user/immunization.read user/insurance.read user/insurance.write user/insurance_company.read user/insurance_company.write user/insurance_type.read user/list.read user/medical_problem.read user/medical_problem.write user/medication.read user/medication.write user/message.write user/patient.read user/patient.write user/practitioner.read user/practitioner.write user/prescription.read user/procedure.read user/soap_note.read user/soap_note.write user/surgery.read user/surgery.write user/vital.read user/vital.write user/AllergyIntolerance.read user/CareTeam.read user/Condition.read user/Coverage.read user/Encounter.read user/Immunization.read user/Location.read user/Medication.read user/MedicationRequest.read user/Observation.read user/Organization.read user/Organization.write user/Patient.read user/Patient.write user/Practitioner.read user/Practitioner.write user/PractitionerRole.read user/Procedure.read patient/encounter.read patient/patient.read patient/AllergyIntolerance.read patient/CareTeam.read patient/Condition.read patient/Encounter.read patient/Immunization.read patient/MedicationRequest.read patient/Observation.read patient/Patient.read patient/Procedure.read"
}'
```
Response should look like
```json
{
  "client_id": "ASGqxau1orFMod1eMzEpqEBtAMyyOcn3IVFS87ZyhOY",
  "client_secret": "lRbpONvPKn2OEzbUXusQOXfcpOXW4O9D8uXH6t5BUqWG4pR3jOhDyMIs_5J2PqNJro13MhaO1frxO3OPv5SXjg",
  "registration_access_token": "a1_8r7nk2PRMFvDc3_KzS7zU3u1ZKryRENc9ZlYyHv4",
  "registration_client_uri": "http:\/\/localhost\/oauth2\/default\/client\/GWtdNGAWj61PtDlgV5rzRg",
  "client_id_issued_at": 1648606367,
  "client_secret_expires_at": 0,
  "client_role": "user",
  "contacts": [
    "bochoi@twilio.com",
    "lpham@twilio.com"
  ],
  "application_type": "private",
  "client_name": "hls-api-client",
  "redirect_uris": [
    "http:\/\/localhost:3000"
  ],
  "post_logout_redirect_uris": [
    "http:\/\/localhost:3000"
  ],
  "token_endpoint_auth_method": "client_secret_post",
  "initiate_login_uri": "http:\/\/localhost:3000",
  "scope": "openid offline_access api:oemr api:fhir api:port user\/allergy.read user\/allergy.write user\/appointment.read user\/appointment.write user\/dental_issue.read user\/dental_issue.write user\/document.read user\/document.write user\/drug.read user\/encounter.read user\/encounter.write user\/facility.read user\/facility.write user\/immunization.read user\/insurance.read user\/insurance.write user\/insurance_company.read user\/insurance_company.write user\/insurance_type.read user\/list.read user\/medical_problem.read user\/medical_problem.write user\/medication.read user\/medication.write user\/message.write user\/patient.read user\/patient.write user\/practitioner.read user\/practitioner.write user\/prescription.read user\/procedure.read user\/soap_note.read user\/soap_note.write user\/surgery.read user\/surgery.write user\/vital.read user\/vital.write user\/AllergyIntolerance.read user\/CareTeam.read user\/Condition.read user\/Coverage.read user\/Encounter.read user\/Immunization.read user\/Location.read user\/Medication.read user\/MedicationRequest.read user\/Observation.read user\/Organization.read user\/Organization.write user\/Patient.read user\/Patient.write user\/Practitioner.read user\/Practitioner.write user\/PractitionerRole.read user\/Procedure.read patient\/encounter.read patient\/patient.read patient\/AllergyIntolerance.read patient\/CareTeam.read patient\/Condition.read patient\/Encounter.read patient\/Immunization.read patient\/MedicationRequest.read patient\/Observation.read patient\/Patient.read patient\/Procedure.read"
}
```

Reference: [API_README#registration](https://github.com/openemr/openemr/blob/master/API_README.md#registration)


### Activate API Client

- Activate API client in OpenEMR by navigating to Administration &#8594; System &#8594; API Clients

![api-clients](assets/images/openemr-api-clients.png)

- Click *'Edit'* Button
- Click *'Enable Client'* that check the box for *'is Enabled'*
- Copy the *'Identifier'* (aka `client_id`) for later use (e.g., lTClKRhUJIQ9tb3TMpsxEHFed7QBiqdiXkz2hPvpW60)

API Client is now ready!


### Access Native & FHIR API

#### Generate Access Token

Newly generated access token will expire in 1 hour (3600 seconds).
Before current access token expires, it can be refreshed. see [Refresh Access Token](#refresh-access-token) below.

Generate access token for `scope` you need via
```shell
curl --location --request POST 'http://localhost/oauth2/default/token' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'client_id=lTClKRhUJIQ9tb3TMpsxEHFed7QBiqdiXkz2hPvpW60' \
--data-urlencode 'grant_type=password' \
--data-urlencode 'user_role=users' \
--data-urlencode 'username=admin' \
--data-urlencode 'password=pass' \
--data-urlencode 'scope=openid offline_access api:oemr api:fhir api:port user/allergy.read user/allergy.write user/appointment.read user/appointment.write user/dental_issue.read user/dental_issue.write user/document.read user/document.write user/drug.read user/encounter.read user/encounter.write user/facility.read user/facility.write user/immunization.read user/insurance.read user/insurance.write user/insurance_company.read user/insurance_company.write user/insurance_type.read user/list.read user/medical_problem.read user/medical_problem.write user/medication.read user/medication.write user/message.write user/patient.read user/patient.write user/practitioner.read user/practitioner.write user/prescription.read user/procedure.read user/soap_note.read user/soap_note.write user/surgery.read user/surgery.write user/vital.read user/vital.write user/AllergyIntolerance.read user/CareTeam.read user/Condition.read user/Encounter.read user/Immunization.read user/Location.read user/Medication.read user/MedicationRequest.read user/Observation.read user/Organization.read user/Organization.write user/Patient.read user/Patient.write user/Practitioner.read user/Practitioner.write user/PractitionerRole.read user/Procedure.read patient/encounter.read patient/patient.read patient/Encounter.read patient/Patient.read' \
| jq .
```

Response will look like
```shell
{
  "id_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiJsVENsS1JoVUpJUTl0YjNUTXBzeEVIRmVkN1FCaXFkaVhrejJoUHZwVzYwIiwiaXNzIjoiaHR0cDpcL1wvbG9jYWxob3N0XC9vYXV0aDJcL2RlZmF1bHQiLCJpYXQiOjE2NDg2MTI3MjQsImV4cCI6MTY0ODYxNjMyNCwic3ViIjoiOTVmMGJlNGItNjFkNy00ZmE3LTg1OWUtNzlkOGMwNzRhM2QxIiwiYXBpOm9lbXIiOnRydWUsImFwaTpmaGlyIjp0cnVlLCJhcGk6cG9ydCI6dHJ1ZX0.DsunJyolqsyp8yjX9I52RDyo-2lAdIrhRd8KvdCcl54ysLafkOMVOW9tq3KW62tcvT76_ROcHognJwjTcu2_F-8Ew1EObwkOt1jQyJPLDP6JgP_-ps8QOKhiTedLKFE5CKLUtUavj3x9-avJ7vT8AbhczTStVEK52bdQf1xScxfHEKORqq-zGKbJlBmbe1r2SUNvsboAUtjTuGGdBzoqRtigudOFreD_57aiBR6JBFSsrZKrEsFfGh8bPXIky8z1OC5xZTtbuWeBKww8qryAi7C38uy_FSnXN0MUgo-zqCHSb0XqZajVV8m-YSafwuMgtiBevy-AUo6Nk2oTsfHcEA",
  "scope": "openid offline_access user\/allergy.read user\/allergy.write user\/appointment.read user\/appointment.write user\/dental_issue.read user\/dental_issue.write user\/document.read user\/document.write user\/drug.read user\/encounter.read user\/encounter.write user\/facility.read user\/facility.write user\/immunization.read user\/insurance.read user\/insurance.write user\/insurance_company.read user\/insurance_company.write user\/insurance_type.read user\/list.read user\/medical_problem.read user\/medical_problem.write user\/medication.read user\/medication.write user\/message.write user\/patient.read user\/patient.write user\/practitioner.read user\/practitioner.write user\/prescription.read user\/procedure.read user\/soap_note.read user\/soap_note.write user\/surgery.read user\/surgery.write user\/vital.read user\/vital.write user\/AllergyIntolerance.read user\/CareTeam.read user\/Condition.read user\/Encounter.read user\/Immunization.read user\/Location.read user\/Medication.read user\/MedicationRequest.read user\/Observation.read user\/Organization.read user\/Organization.write user\/Patient.read user\/Patient.write user\/Practitioner.read user\/Practitioner.write user\/PractitionerRole.read user\/Procedure.read patient\/encounter.read patient\/patient.read patient\/Encounter.read patient\/Patient.read",
  "token_type": "Bearer",
  "expires_in": 3600,
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiJsVENsS1JoVUpJUTl0YjNUTXBzeEVIRmVkN1FCaXFkaVhrejJoUHZwVzYwIiwianRpIjoiYzZiNjhmYjVlYWVjNzNkMWMzNjM5N2MyNGYwYzIxNGRmMzIzM2QyNzM4YmJlZGMyODg1NTA3MmQzOTI0ZTNkODE5YzY3MTQwMzJmNjVjNDYiLCJpYXQiOjE2NDg2MTI3MjQsIm5iZiI6MTY0ODYxMjcyNCwiZXhwIjoxNjQ4NjE2MzI0LCJzdWIiOiI5NWYwYmU0Yi02MWQ3LTRmYTctODU5ZS03OWQ4YzA3NGEzZDEiLCJzY29wZXMiOlsib3BlbmlkIiwib2ZmbGluZV9hY2Nlc3MiLCJhcGk6b2VtciIsImFwaTpmaGlyIiwiYXBpOnBvcnQiLCJ1c2VyXC9hbGxlcmd5LnJlYWQiLCJ1c2VyXC9hbGxlcmd5LndyaXRlIiwidXNlclwvYXBwb2ludG1lbnQucmVhZCIsInVzZXJcL2FwcG9pbnRtZW50LndyaXRlIiwidXNlclwvZGVudGFsX2lzc3VlLnJlYWQiLCJ1c2VyXC9kZW50YWxfaXNzdWUud3JpdGUiLCJ1c2VyXC9kb2N1bWVudC5yZWFkIiwidXNlclwvZG9jdW1lbnQud3JpdGUiLCJ1c2VyXC9kcnVnLnJlYWQiLCJ1c2VyXC9lbmNvdW50ZXIucmVhZCIsInVzZXJcL2VuY291bnRlci53cml0ZSIsInVzZXJcL2ZhY2lsaXR5LnJlYWQiLCJ1c2VyXC9mYWNpbGl0eS53cml0ZSIsInVzZXJcL2ltbXVuaXphdGlvbi5yZWFkIiwidXNlclwvaW5zdXJhbmNlLnJlYWQiLCJ1c2VyXC9pbnN1cmFuY2Uud3JpdGUiLCJ1c2VyXC9pbnN1cmFuY2VfY29tcGFueS5yZWFkIiwidXNlclwvaW5zdXJhbmNlX2NvbXBhbnkud3JpdGUiLCJ1c2VyXC9pbnN1cmFuY2VfdHlwZS5yZWFkIiwidXNlclwvbGlzdC5yZWFkIiwidXNlclwvbWVkaWNhbF9wcm9ibGVtLnJlYWQiLCJ1c2VyXC9tZWRpY2FsX3Byb2JsZW0ud3JpdGUiLCJ1c2VyXC9tZWRpY2F0aW9uLnJlYWQiLCJ1c2VyXC9tZWRpY2F0aW9uLndyaXRlIiwidXNlclwvbWVzc2FnZS53cml0ZSIsInVzZXJcL3BhdGllbnQucmVhZCIsInVzZXJcL3BhdGllbnQud3JpdGUiLCJ1c2VyXC9wcmFjdGl0aW9uZXIucmVhZCIsInVzZXJcL3ByYWN0aXRpb25lci53cml0ZSIsInVzZXJcL3ByZXNjcmlwdGlvbi5yZWFkIiwidXNlclwvcHJvY2VkdXJlLnJlYWQiLCJ1c2VyXC9zb2FwX25vdGUucmVhZCIsInVzZXJcL3NvYXBfbm90ZS53cml0ZSIsInVzZXJcL3N1cmdlcnkucmVhZCIsInVzZXJcL3N1cmdlcnkud3JpdGUiLCJ1c2VyXC92aXRhbC5yZWFkIiwidXNlclwvdml0YWwud3JpdGUiLCJ1c2VyXC9BbGxlcmd5SW50b2xlcmFuY2UucmVhZCIsInVzZXJcL0NhcmVUZWFtLnJlYWQiLCJ1c2VyXC9Db25kaXRpb24ucmVhZCIsInVzZXJcL0VuY291bnRlci5yZWFkIiwidXNlclwvSW1tdW5pemF0aW9uLnJlYWQiLCJ1c2VyXC9Mb2NhdGlvbi5yZWFkIiwidXNlclwvTWVkaWNhdGlvbi5yZWFkIiwidXNlclwvTWVkaWNhdGlvblJlcXVlc3QucmVhZCIsInVzZXJcL09ic2VydmF0aW9uLnJlYWQiLCJ1c2VyXC9Pcmdhbml6YXRpb24ucmVhZCIsInVzZXJcL09yZ2FuaXphdGlvbi53cml0ZSIsInVzZXJcL1BhdGllbnQucmVhZCIsInVzZXJcL1BhdGllbnQud3JpdGUiLCJ1c2VyXC9QcmFjdGl0aW9uZXIucmVhZCIsInVzZXJcL1ByYWN0aXRpb25lci53cml0ZSIsInVzZXJcL1ByYWN0aXRpb25lclJvbGUucmVhZCIsInVzZXJcL1Byb2NlZHVyZS5yZWFkIiwicGF0aWVudFwvZW5jb3VudGVyLnJlYWQiLCJwYXRpZW50XC9wYXRpZW50LnJlYWQiLCJwYXRpZW50XC9FbmNvdW50ZXIucmVhZCIsInBhdGllbnRcL1BhdGllbnQucmVhZCIsInNpdGU6ZGVmYXVsdCJdfQ.WqVZjYhTQJOzVv7jLGWkDcpjErk83plx5pk-jqvKVmeTSLIJObJ6Kz9YZ7urTSI2DePqqVXmmFG3sh0qnJUPEBIiOrdLu4lbIYS4J9JqfvKU-GupcqL1MWmNjX5MVhfXmw97zUBuNA6RPUUQ_RedQTtYFhE7mIjAbDzchXJ-L4gPet9tp1RDULiHDS4iVQ1gebIKcbBFubtJE2R1MrUFODZpMhQU2ZoC9ywCR_HPKuBXgXsbJxYg_cSm5SrmaeN3tcBjnBRyhY-F9hekQEG8J26toECysp5Rx81W-lgICnlktXhQsH6Aag0A1HupPNNYMG-zH3p27TrbrG-S2jplVA",
  "refresh_token": "def502006efe1cbb0d40e3f19b8f3ed1b257a36a35afa10ab6069da9651b61ae588e59def29a689bb38e21b0d562fe923776f4269bac670f974a181f86efb82ae5a6d063d5f0f937fd49800a6147201680c53751f6bf807fb110d84e46ffb4adca0efcd9f11807f172b2bd513a834e18d3eaa5a5b9b51566d364ce8d93cd83c5bfc0443b2bfef49d18d3838646d6df107aac50f91aa9a3167b4e21fae33ddf37399fed6a8421c811db91dd24ecd3256f928808f54ea2a1161268fd2b3c66fcb43cddb1f4ba911e1bc6225412c4d15b0f7d35e4ac0b827d74bb2b788eaf4e431ad4b98a10056f99ed585ffee09af936775bf8463b732e7b190639cdb91e85da3b881a723a494d0b6afc7787572dd6cd185d014c8139a93da7653d04d54af705b97cbe25771aa1883a05b6d1629f01a30055a770d46fcb157a1b1f3c998a9c0294168449663cad9f671e0fa7308946fbb10dbe9c1ca8d9b98d078b57cb5f2b9874a26068057c32f3c6206fe2dafc693a627b68ec209dd8396b29e66d620a7460f44ec9005e1e6551c096a5e144bb67cb8da590fde10884ceef05962261d0ee99e7edeb6dc5440f221c062a614d88da1fa5e10c782dbcd3b15f42b5d5598f5cceeb243d04e53d2ed5379b052ded2f4af6c6e29d54c4ea7695b71e99d6e571606071376ebbeb2c94da46818053f1bf74f80fcc110d19eaa1c47ad5d26af13865135554f859304c17e2b70e7f3f22526fea2475dfd46c9558aede66230e2d4519563e7d0aa5e0f75f0ac15dc27e8f6c5ee4f8d5a0a17ec4fa84bf9b3a81e3a6e40f88efb098b63ae40831f930011b5a655c192bd3ac8a9c01b4584a442349ead6ffcc75d430ae0707225bfd743ff1297f1e8512d26c30779dab716314bc55c36cba1f4807f53bfc4ab25a4f2c335fb088bb440c9ca5c66a471e710042c3ce05384e6cb12d93c82724de6a9c8d8a4e40ebdeb7d83b87ba8d8f77d4db66baf4014e5888440004f5a938ba329e63871120fa12bb125f19803be5465107a117b2ed74eea04cb37012351507b9a23133aa6e94b10c148a5ef118ee8f63459c110496437c547189a858d0d31f8af3d82c34e6c18eaf639eafa805bea7c6235de9b290b03d91cf079f740f557f9327e26778552d18b90064a886f3a75c8acbec9aaa52c2f1fe21cd7e3a4188dfb3ad8bbc40ce734e85e80cb949da205f276e4f8f52dab9d340ece96739a633bcb6d1783a7c24184ab34e5ea01a95359de84e421447c9e5579398e9bfc10334a46d44c48ee2b6ca54b17969d35a826753cd4c79f3a12267cf81e8cf8db62bcf13c84adfc3e27f0b3b62f5e05690d235e5d09671da72dae42ce49656d4a9f375ef44e8a32ee20c4ed4011b514eed26a8c3a7e1df27c3eda2d181e3fccd43f98f94d29b44679082ab2bbecff054d167a1db27c7507a798043a8aa601ccab06fa31be601f9e14ee2b258471b47f6af5132250e0fe27cb2f8be92825183c29de7a21c34c3b5b9b4afb2ae609a0e24fc29dca26c043d94b63b6c4f532a71313b08d78d9f153e092426bc7568bc6948322b742ffecf7c293878d3c3060360d3c08ec65e868f0d82ef728fe479ae9390e45c5a1510b79d9fa4c3f05cf4bc449e0af1bfd9029b7810e8de8d05bbdb11b9da61201ceab79b423ef18231f553066a534822c5525e0bd467e9fb78bc96635b36c5651a779922c43bc69bb9017ba0edb63cc1e26b6ccc791c61622c1ff2558f4b80236bd50788443bc4812dc22e67f4037aa666ac3bace4448a10a04340429ae105292a2dc023fb95b55bc5299d703f14a4262e8bc7ba8734c401829bdf7a2e4168c9589a7259e996d3400f9f7d7e55cbb863a1012769c3dd571d0c36a787423fb500fc37b05404a7b19fdaff88e8407e2c8771288067bf03ad64f6d37aabca872c77d2c197292107a6f81f7b3929bbfca8b7abd23c3e32ab932ee0d0bce86b3164b05582803be8fa69341afcf87afdaac99e2b6b784d4f7a3aa1bfa1529e11fc590e67197163a2c47ea845187eca1cf039cc40cfe7de927c1ef85266903338e003dbf0d5bddf044fd82ef30516dcf948c825e8e8af47c0fad0c69abe59ef01122c0c8c4510f22935a0e7b5bfb4849ccb8d3dcf8273a8fa35e5548685a7c47f6cb6a5051fc33281862de3dd1e3918ffa46494fe9f86783f5ef9f88035bb7e76d452a695f69d0a3383e1b9ffec472b9eac670afffa31aec25c176fe01c35b4f6ecd93fffd972f788cc944ef38800a748b0a3585a4633668d0978ac38d93fc7f6c0bc60359caf7439b95d5ccb79bca0df3e14179fc1523871652ce5a053a1ac146411f3661e086648372804f7ca93b16b77d917beb817ea4b35442d8f7cda7714796aca9113bf78f3babed8e3212bf8fcb01bbd1c9c9a0ebdc3276390054ba95073f869df734384eb45651b39d6a1a28bc662ac335cd0a6d46bd107d73b9df007a7fb1b1ae43dccea1d8ec779b3eb20eb3a2a7bf3e6347b18846c85b783e6c014ff26a2fc47d0733a2d2b6bdd7ad4f2c13c5bba2f3c2464f4dd3100f9638def15161c8e129dfe63c281a6912b51b1c2cd0765d1575fb6dc4cde029bb31067e75346d4f961d49e796079225fa2165cad8a7f928cd0c6515b116e29d920cef00a7a93e5f3312abbe0f275f97aeb7864d4fea0687cccef9583b98780180755690704c002cd02bb78c364bb49c39fe4b27cef"
}
```

`access_token` will be the bearer token for subsequent API access

```shell
ACCESS_TOKEN=eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiJsVENsS1JoVUpJUTl0YjNUTXBzeEVIRmVkN1FCaXFkaVhrejJoUHZwVzYwIiwianRpIjoiYzZiNjhmYjVlYWVjNzNkMWMzNjM5N2MyNGYwYzIxNGRmMzIzM2QyNzM4YmJlZGMyODg1NTA3MmQzOTI0ZTNkODE5YzY3MTQwMzJmNjVjNDYiLCJpYXQiOjE2NDg2MTI3MjQsIm5iZiI6MTY0ODYxMjcyNCwiZXhwIjoxNjQ4NjE2MzI0LCJzdWIiOiI5NWYwYmU0Yi02MWQ3LTRmYTctODU5ZS03OWQ4YzA3NGEzZDEiLCJzY29wZXMiOlsib3BlbmlkIiwib2ZmbGluZV9hY2Nlc3MiLCJhcGk6b2VtciIsImFwaTpmaGlyIiwiYXBpOnBvcnQiLCJ1c2VyXC9hbGxlcmd5LnJlYWQiLCJ1c2VyXC9hbGxlcmd5LndyaXRlIiwidXNlclwvYXBwb2ludG1lbnQucmVhZCIsInVzZXJcL2FwcG9pbnRtZW50LndyaXRlIiwidXNlclwvZGVudGFsX2lzc3VlLnJlYWQiLCJ1c2VyXC9kZW50YWxfaXNzdWUud3JpdGUiLCJ1c2VyXC9kb2N1bWVudC5yZWFkIiwidXNlclwvZG9jdW1lbnQud3JpdGUiLCJ1c2VyXC9kcnVnLnJlYWQiLCJ1c2VyXC9lbmNvdW50ZXIucmVhZCIsInVzZXJcL2VuY291bnRlci53cml0ZSIsInVzZXJcL2ZhY2lsaXR5LnJlYWQiLCJ1c2VyXC9mYWNpbGl0eS53cml0ZSIsInVzZXJcL2ltbXVuaXphdGlvbi5yZWFkIiwidXNlclwvaW5zdXJhbmNlLnJlYWQiLCJ1c2VyXC9pbnN1cmFuY2Uud3JpdGUiLCJ1c2VyXC9pbnN1cmFuY2VfY29tcGFueS5yZWFkIiwidXNlclwvaW5zdXJhbmNlX2NvbXBhbnkud3JpdGUiLCJ1c2VyXC9pbnN1cmFuY2VfdHlwZS5yZWFkIiwidXNlclwvbGlzdC5yZWFkIiwidXNlclwvbWVkaWNhbF9wcm9ibGVtLnJlYWQiLCJ1c2VyXC9tZWRpY2FsX3Byb2JsZW0ud3JpdGUiLCJ1c2VyXC9tZWRpY2F0aW9uLnJlYWQiLCJ1c2VyXC9tZWRpY2F0aW9uLndyaXRlIiwidXNlclwvbWVzc2FnZS53cml0ZSIsInVzZXJcL3BhdGllbnQucmVhZCIsInVzZXJcL3BhdGllbnQud3JpdGUiLCJ1c2VyXC9wcmFjdGl0aW9uZXIucmVhZCIsInVzZXJcL3ByYWN0aXRpb25lci53cml0ZSIsInVzZXJcL3ByZXNjcmlwdGlvbi5yZWFkIiwidXNlclwvcHJvY2VkdXJlLnJlYWQiLCJ1c2VyXC9zb2FwX25vdGUucmVhZCIsInVzZXJcL3NvYXBfbm90ZS53cml0ZSIsInVzZXJcL3N1cmdlcnkucmVhZCIsInVzZXJcL3N1cmdlcnkud3JpdGUiLCJ1c2VyXC92aXRhbC5yZWFkIiwidXNlclwvdml0YWwud3JpdGUiLCJ1c2VyXC9BbGxlcmd5SW50b2xlcmFuY2UucmVhZCIsInVzZXJcL0NhcmVUZWFtLnJlYWQiLCJ1c2VyXC9Db25kaXRpb24ucmVhZCIsInVzZXJcL0VuY291bnRlci5yZWFkIiwidXNlclwvSW1tdW5pemF0aW9uLnJlYWQiLCJ1c2VyXC9Mb2NhdGlvbi5yZWFkIiwidXNlclwvTWVkaWNhdGlvbi5yZWFkIiwidXNlclwvTWVkaWNhdGlvblJlcXVlc3QucmVhZCIsInVzZXJcL09ic2VydmF0aW9uLnJlYWQiLCJ1c2VyXC9Pcmdhbml6YXRpb24ucmVhZCIsInVzZXJcL09yZ2FuaXphdGlvbi53cml0ZSIsInVzZXJcL1BhdGllbnQucmVhZCIsInVzZXJcL1BhdGllbnQud3JpdGUiLCJ1c2VyXC9QcmFjdGl0aW9uZXIucmVhZCIsInVzZXJcL1ByYWN0aXRpb25lci53cml0ZSIsInVzZXJcL1ByYWN0aXRpb25lclJvbGUucmVhZCIsInVzZXJcL1Byb2NlZHVyZS5yZWFkIiwicGF0aWVudFwvZW5jb3VudGVyLnJlYWQiLCJwYXRpZW50XC9wYXRpZW50LnJlYWQiLCJwYXRpZW50XC9FbmNvdW50ZXIucmVhZCIsInBhdGllbnRcL1BhdGllbnQucmVhZCIsInNpdGU6ZGVmYXVsdCJdfQ.WqVZjYhTQJOzVv7jLGWkDcpjErk83plx5pk-jqvKVmeTSLIJObJ6Kz9YZ7urTSI2DePqqVXmmFG3sh0qnJUPEBIiOrdLu4lbIYS4J9JqfvKU-GupcqL1MWmNjX5MVhfXmw97zUBuNA6RPUUQ_RedQTtYFhE7mIjAbDzchXJ-L4gPet9tp1RDULiHDS4iVQ1gebIKcbBFubtJE2R1MrUFODZpMhQU2ZoC9ywCR_HPKuBXgXsbJxYg_cSm5SrmaeN3tcBjnBRyhY-F9hekQEG8J26toECysp5Rx81W-lgICnlktXhQsH6Aag0A1HupPNNYMG-zH3p27TrbrG-S2jplVA
```

#### Refresh Access Token

The inital access token **must** include `offline_access` in the `scope` parameter.

Request will look like
```shell
curl -X POST -k -H 'Content-Type: application/x-www-form-urlencoded'
-i 'https://localhost:9300/oauth2/default/token'
--data 'grant_type=refresh_token
&client_id=lTClKRhUJIQ9tb3TMpsxEHFed7QBiqdiXkz2hPvpW60
&refresh_token=def5020089a766d16...'
```

Response will look like
```json
{
  "id_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiJrYn...",
  "token_type": "Bearer",
  "expires_in": 3599,
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiJrYnl1RkRp...",
  "refresh_token": "def5020017b484b0add020bf3491a8a537fa04eda12..."
}
```


#### Access Native API (Patient)

Get all patients

```shell
curl --location --request GET 'http://localhost/apis/default/api/patient' \
--header "Authorization: Bearer ${ACCESS_TOKEN}" \
| jq '.[0]'
```

response should look like

```json
{
  "validationErrors": [],
  "internalErrors": [],
  "data": [
    {
      "id": "1",
      "pid": "1",
      "uuid": "9564987e-0899-4528-95a0-d5e88741cf51",
      "pubpid": "12-37-36",
      "title": "Mr.",
      "fname": "Alexander",
      "mname": "",
      "lname": "Pickett",
      "ss": "123-54-3678",
      "street": "",
      "postal_code": "",
      "city": "",
      "state": "",
      "county": "",
      "country_code": "",
      "drivers_license": "123876526783",
      "contact_relationship": "",
      "phone_contact": "",
      "phone_home": "",
      "phone_biz": "",
      "phone_cell": "432-624-8573",
      "email": "",
      "DOB": "1976-01-11",
      "sex": "Male",
      "race": "",
      "ethnicity": "",
      "status": "married"
    },
...
```

#### Access FHIR API (Patient)

Get all patients

```shell
curl --location --request GET 'http://localhost/apis/default/fhir/Patient' \
--header "Authorization: Bearer ${ACCESS_TOKEN}" \
| jq '.[0]'
```

response should look like

```json
{
  "meta": {
    "lastUpdated": "2022-03-30T04:10:43"
  },
  "resourceType": "Bundle",
  "type": "collection",
  "total": 18,
  "link": [
    {
      "relation": "self",
      "url": "http://localhost/apis/default/fhir/Patient"
    }
  ],
  "entry": [
    {
      "fullUrl": "http://localhost/apis/default/fhir/Patient/9564987e-0899-4528-95a0-d5e88741cf51",
      "resource": {
        "id": "9564987e-0899-4528-95a0-d5e88741cf51",
        "meta": {
          "versionId": "1",
          "lastUpdated": "2022-03-30T04:10:43+00:00"
        },
        "resourceType": "Patient",
        "text": {
          "status": "generated",
          "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"> <p>Alexander Pickett</p></div>"
        },
        "identifier": [
...
```

### API Client Template Code

|`.env` variables| notes |
|----------------|-------|
|OPENEMR_ENDPOINT|http://localhost:80|
|OPENEMR_CLIENT_ID|lTClKRhUJIQ9tb3TMpsxEHFed7QBiqdiXkz2hPvpW60|
|SYNC_SID|Twilio Sync Service SID|

Reference the following files to include into your application (e.g, hls-flex-provider).

```shell
functions/flex-find-patient.js
functions/helpers-openemr.private.js
herlps.private.js
```



--------------------------------------------------------------------------------
## Initial Setup of HLS-EHR stack

### OpenEMR

After deployment of docker compose stack, cd to `assets/ehr/openemr` directory and execute the following:

- `mirth.appointment_events` table for interface engine
    ```shell
    docker exec --interactive openemr_db mysql --user=root --password=root openemr < create_appointment_events_table.sql
    ```

- appointment insert & update trigger
    ```shell
    docker exec --interactive openemr_db mysql --user=root --password=root openemr < create_appointment_insert_trigger.sql
    ```
    ```shell
    docker exec --interactive openemr_db mysql --user=root --password=root openemr < create_appointment_update_trigger.sql
    ```

- patient update trigger
    ```shell
    docker exec --interactive openemr_db mysql --user=root --password=root openemr < create_patient_update_trigger.sql
    ```

When patient & appointment data is created/updated in openEMR as part of seed demo data
, the triggers must be disabled first and re-enabled afterwards to suppress firing.

To disable triggers, temporarily drop them and re-create them.
```shell
openemr $ docker exec -i openemr_db mysql --user=root --password=root openemr < drop_all_triggers.sql
```

### OpenEMR IE (Mirth Interface Engine)

TODO

### Mirth

TODO


--------------------------------------------------------------------------------
## Archive

Below are archive old documentation and therefore may not be accurate and/or complete.

Examine the docker dashboard and check that all 6 docker containers are running (i.e., green) like below.

![Docker Dashboard with HLS-EHR Running](assets/images/docker-dashboard.png)


### Configure OpenEMR

- If first-time, clone the git repo that will create a directory `hls-ehr` where you run the command below
```shell
$ git clone https://github.com/bochoi-twlo/hls-ehr
```

- get latest from git repo by executing the following from inside the `hls-ehr` directory
```shell
hls-ehr$ git pull
```

- Restore appropriate (e.g., sko) backup
```shell
hls-ehr$ cd assets/hls-ehr/openemr
openemr$ ./restore-volumes.sh sko
Restoring backups:
  openemr_db_sko.tar.gz
  openemr_app_sko.tar.gz
Stopping mirth_app     ... done
Stopping openemr_ie    ... done
Stopping openemr_app   ... done
Stopping mirth_db      ... done
Stopping openemr_ie_db ... done
Stopping openemr_db    ... done

restore volume on CONTAINER=openemr_db from openemr_db_sko.tar.gz

restore volume on CONTAINER=openemr_app from openemr_app_sko.tar.gz

Starting openemr_db    ... done
Starting openemr_app   ... done
Starting openemr_ie_db ... done
Starting openemr_ie    ... done
Starting mirth_db      ... done
Starting mirth_app     ... done
```

- Launch CLI for `openemr_app` container via Docker desktop, once your CLI terminal opens copy & paste the following:
```shell
hls-ehr $ cd assets/hls-ehr/openemr
openemr $ docker exec -i openemr_app /bin/sh < script_fix_iframe.sh
```

- Restart `openemr_app` container via Docker desktop

- Wait 30 seconds ...

- Launch chrome via cli. For windows command go [here](https://stackoverflow.com/questions/3102819/disable-same-origin-policy-in-chrome)
```shell
open -na Google\ Chrome --args --user-data-dir=/tmp/temporary-chrome-profile-dir --disable-web-security --disable-site-isolation-trials
```

- Via chrome setting -> security & privacy, clear browsing data for 'Cached images and files'

- Open http://localhost:80/

- Select 'No Thanks' in registration window ![OpenEMR Registration Window](assets/hls-ehr/images/openemr-registration.png)

- Login using credentials `admin/pass` ![OpneEMR Login](assets/images/openemr-login.png)

- For SKO Demo, you can **ONLY** do the following as openEMR is inside an iframe:

  - filter "Patient Finder"
  - select a patient
  - open "Calender" from upper-left menu
    - changing provider
    - changing period (i.e., day/week/month view)

  - **does NOT YET work**

    - click time to create appointment

### Advanced Appointment Dates by 1 Week

Each time the `script_advance_appointments_one_week.sql` is run, the all appointment dates in openEMR
will advance by 1 week.

From main directory (`.../hls-ehr`)
```shell
hls-ehr $ cd assets/hls-ehr/openemr
openemr $ docker exec -i openemr_db mysql -u root -proot openemr < script_advance_appointments_one_week.sql
```

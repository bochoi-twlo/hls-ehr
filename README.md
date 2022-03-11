# HLS EMR 

##### Table of Contents
- [Pre-requisites](#pre-requisites)
- [Deploy HLS-EHR](#deploy)
- [Using HLS-EHR](#use)
- [Developer Notes](#developer)


This document details the requirements for deployment and configuration of HLS EHR.

HLS EHR is deployed using docker compose [docker-compose.yml](https://github.com/bochoi-twlo/hls-ehr/blob/main/docker-compose.yml).


<a name="pre-requisites"/>

## Pre-requisites

---

The following prerequisites must be satisfied prior to installing the application.

### Docker Desktop

Install Docker desktop that includes docker compose CLI will be used to run the application installer locally on your machine.
Goto [Docker Desktop](https://www.docker.com/products/docker-desktop) and install with default options.
After installation make sure to start Docker desktop.

### Allow Chrome Insecure `localhost` Connection

OpenEMR & Mirth run over the insecure http (as opposed to certificate backed https)
, we recommend that you use chrome only and allow chrome to open connections to insecure localhost.

Either manually open a new chrome tab and open -a Google\ Chrome `chrome://flags/#allow-insecure-localhost`

Or, use terminal to execute: `open -a Google\ Chrome chrome://flags/#allow-insecure-localhost`

Chrome tab should open as below:
![Chrome Flags](assets/images/chrome-flag.png)

Set the option to 'Enabled' for 'Allow invalid certificate for resources loaded from localhost.'

Note that this will re-launch chrome.


### jq & xq

```shell
$ brew install jq           # install jq
...
$ jq --version              # confirm installation
jq-1.6
$ brew install python-yq    # install yq/xq
...
$ yq --version              # confirm installation
yq 2.13.0
```

### ngrok

If you will demo a blue print that will need to connect back to your macbook from the internet (e.g., "patient appointment management"), you need to install a reverse proxy.

```shell
brew install ngrok/ngrok/ngrok
```

If you have twilio email, register at `ngrok.com` using your twilio email.
Login to `ngrok.com` and follow step 2. to connect your `ngrok` on your laptop to your account.

```shell
ngrok authtoken your-ngrok-auth-token
```


and get yourself invited from hls team mebmer to assign a static ngrok url for yourself
(e.g., `bochoi.ngrok.io`).

Once you are registered, you can sign into https://dashboard.ngrok.com/team/members

To start ngrok using your static ngrok URL on local port 80
```shell
ngrok http --region=us --hostname=bochoi.ngrok.io 80
```


<a name="deploy"/>

## Deploy HLS-EHR

---

### Clean-up Previous Installation (Optional)

Installer can remove, existing installation of docker compose stack named `hls-ehr`.
However, if you have previous installed openEMR using a different docker compose stack
, please remove the running docker container and image via the Docker Desktop or via command line

```shell
docker-compose --project-name your-openemr-stack-name down
```

After container and image removal, unsued volumes need to be removed via
```shell
docker volume prune --force
```

<a name="pam"/>

### Patient-Appointment-Management Integration (Optional)

In order to integrate with patient-appointment-management integration
, you **must** have `patient-appointment-managment` blueprint deployed in your target twilio account
so that the HLS-EHR installer can detect it.

After HLS-EHR installation, integration will work immediately.

Remember that after HLS-EHR installation, `ngrok` will need to running in order to receive 2-way SMS.


<a name="build" />

### Build Installer Docker Image

```shell
docker build --tag hls-ehr-installer --no-cache https://github.com/bochoi-twlo/hls-ehr.git#main
```

For machines running Apple M1 chip add the option `--platform linux/amd64`.

Alternatively, if you have git repo cloned locally
```shell
docker build --tag hls-ehr-installer --no-cache .
```

<a name="run" />

### Run Installer Docker Container

Please ensure that you do not have any running processes that is listening on port 3000
such development servers or another HLS docker installer still running.

Replace `${TWILIO_ACCOUNT_SID}` and `${TWILIO_AUTH_TOKEN}` with that of your target Twilio account.
Alternatively, have environment variable set in your terminal.

```shell
docker run --name hls-ehr-installer --rm --publish 3000:3000  \
--volume /var/run/docker.sock:/var/run/docker.sock \
--env ACCOUNT_SID=${TWILIO_ACCOUNT_SID} --env AUTH_TOKEN=${TWILIO_AUTH_TOKEN} \
--interactive --tty hls-ehr-installer
```

For machines running Apple M1 chip add the option `--platform linux/amd64`.

Monitor the output of the terminal and wait upto a minute for installer to startup.

Open http://localhost:3000/installer/index.html.

### Install

Follow instruction in the installer while keeping terminal window visible to monitor long processes running.

### Stop Installer

Once installation is complete, you can enter Control-C in the terminal to quit the installer
, or alternatively remove the `hls-ehr-installer` docker container via the Docker Desktop

Note that it may take a minute for installer docker container stopped properly and disappear.


<a name="use"/>

## Using HLS-EHR

---

### Open directly

Either click the link `Open EHR` in the installer
that will open http://localhost:80/interface/login/login.php?site=default
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


<a name="developer"/>

# Developer Notes

---

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


### Mirth


# Archive, ignore

1. Download `docker-compose.yml` from github: 
[download](https://raw.githubusercontent.com/bochoi-twlo/hls-ehr/main/assets/hls-ehr/docker-compose.yml).

2. Launch a fresh instance of `hls-ehr` docker compose stack.

```shell
$ docker-compose --project-name hls-ehr up -d
[+] Running 12/12
Creating network "hls-ehr_default" with the default driver
Creating volume "hls-ehr_v_openemr_log" with default driver
Creating volume "hls-ehr_v_openemr_site" with default driver
Creating volume "hls-ehr_v_openemr_db" with default driver
Creating volume "hls-ehr_v_openemr_ie_app" with default driver
Creating volume "hls-ehr_v_mirth_app" with default driver
Creating openemr_ie_db ... done
Creating openemr_db    ... done
Creating mirth_db      ... done
Creating openemr_app   ... done
Creating openemr_ie    ... done
Creating mirth_app     ... done
```

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

#### Advanced Appointment Dates by 1 Week

Each time the `script_advance_appointments_one_week.sql` is run, the all appointment dates in openEMR
will advance by 1 week.

From main directory (`.../hls-ehr`)
```shell
hls-ehr $ cd assets/hls-ehr/openemr
openemr $ docker exec -i openemr_db mysql -u root -proot openemr < script_advance_appointments_one_week.sql
```

## Installer



[![](https://img.shields.io/badge/enabled-blue?style=for-the-badge)]()

[![](https://img.shields.io/badge/enabled-blue)]()


```diff
- fdfsfsf
```


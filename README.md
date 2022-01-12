# HLS EMR 


## <a name="install"></a>Installation Information
___

This section details the requirements for a successful deployment and installation of HLS EHR using the following:

- 1 instance of OpenEMR 6.0.0
- 2 instances of Mirth Connect 3.10.0:
  - 1 instance used as OpenEMR companion HL7 interface engine
  - 1 instance used as Healthsystem interface engine


## Prerequisites

The following prerequisites must be satisfied prior to installing the application.

**Install Docker Desktop**

Docker desktop that includes docker compose CLI will be used to run the application installer locally on your machine.
Goto [Docker Desktop](https://www.docker.com/products/docker-desktop)
and install with default options.
After installation make sure to start Docker desktop.

**Install jq & xq**

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

**ngrok reverse proxy, optional**

If you will demo a blue print that will need to connect back to your macbook from the internet (e.g., "patient appointment management"), you need to install a reverse proxy.

Download ngrok from `https://ngrok.com/download`

Follow instruction from ngrok to unzip (FYI, there is internal initiative to get enterprise license for ngrok that will assign static URL, will update this when it is place)

Drag the `ngrok` application into your `/Applications` folder

**Allow Chrome Insecure Localhost Connection**

OpenEMR & Mirth run over the insecure http (as opposed to certificate backed https), we recommend that you use chrome and allow chrome to open connections to insecure localhost.

In a new chrome tab, open `chrome://flags/#allow-insecure-localhost` and set the option to enabled on `allow-insecure-localhost`.
Note that this will re-launch chrome.



## Install HLS-EHR

### Clean-up Previous Installation
If you already have a previous `hls-ehr` docker compose application running or are updating to a new version of docker stack,

- Open Docker dashboard and locate previous `hls-ehr` application
- Click the 'Delete' trash can button on the application
- Click 'Remove' in the 'Remove application' dialog
- Wait for application to be completely removed
- Delete the volumes
```shell
$ docker volume prune
WARNING! This will remove all local volumes not used by at least one container.
Are you sure you want to continue? [y/N] y
...
Total reclaimed space: 179.2MB
```

### Install HLS-EHR Docker Compose

1. Download `docker-compose.yml` from github [here](https://github.com/bochoi-twlo/hls-ehr/blob/main/assets/hls-ehr/docker-compose.yml)

2. Launch a fresh instance of `hls-ehr` docker compose stack.

```shell
$ docker-compose --project-name hls-ehr up -d
[+] Running 12/12
 ⠿ Network hls-ehr_default            Created
 ⠿ Volume "hls-ehr_v_openemr_site"    Created
 ⠿ Volume "hls-ehr_v_openemr_ie_app"  Created
 ⠿ Volume "hls-ehr_v_mirth_app"       Created
 ⠿ Volume "hls-ehr_v_openemr_db"      Created
 ⠿ Volume "hls-ehr_v_openemr_log"     Created
 ⠿ Container openemr_ie_db            Started
 ⠿ Container openemr_db               Started
 ⠿ Container mirth_db                 Started
 ⠿ Container openemr_app              Started
 ⠿ Container openemr_ie               Started
 ⠿ Container mirth_app                Started
```

Examine the docker dashboard and check that all 6 docker containers are running (i.e., green) like below.

![Docker Dashboard with HLS-EHR Running](assets/images/docker-dashboard.png)


### Validate Installation

#### OpenEMR

- Open http://localhost:80/


- Select 'No Thanks' in registration window ![OpenEMR Registration Window](assets/images/openemr-registration.png)


- Login using credentials `admin/pass` ![OpneEMR Login](assets/images/openemr-login.png)


- OpenEMR Calender pane will display initially ![OpneEMR Initial](assets/images/openemr-initial.png)
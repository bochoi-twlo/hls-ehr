# --------------------------------------------------------------------------------------------------------------
# FOR DEVELOPER USE ONLY!!!
# --------------------------------------------------------------------------------------------------------------

# ---------- check twilio credentials from environment variables
# when below 2 variables are set, it will be the 'active' profile of twilio cli
ifndef TWILIO_ACCOUNT_SID
$(info Lookup your "ACCOUNT SID" at https://console.twilio.com/)
$(info execute in your terminal, 'export TWILIO_ACCOUNT_SID=AC********************************')
$(error TWILIO_ACCOUNT_SID environment variable is not set)
endif

ifndef TWILIO_AUTH_TOKEN
$(info Lookup your "AUTH TOKEN" at https://console.twilio.com/)
$(info execute in your terminal, 'export TWILIO_AUTH_TOKEN=********************************')
$(info TWILIO_AUTH_TOKEN environment variable is not set)
endif


# ---------- variables
BLUEPRINT_NAME   := $(shell basename `pwd`)
SERVICE_NAME     := $(BLUEPRINT_NAME)-server
GIT_REPO_URL     := $(shell git config --get remote.origin.url)
VERSION          := $(shell jq --raw-output .version package.json)
INSTALLER_NAME   := hls-ehr-installer
INSTALLER_TAG_V  := twiliohls/$(INSTALLER_NAME):$(VERSION)
INSTALLER_TAG_L  := twiliohls/$(INSTALLER_NAME):latest
CPU_HARDWARE     := $(shell uname -m)
DOCKER_EMULATION := $(shell [[ `uname -m` == "arm64" ]] && echo --platform linux/amd64)
$(info ================================================================================)
$(info BLUEPRINT_NAME     : $(BLUEPRINT_NAME))
$(info GIT_REPO_URL       : $(GIT_REPO_URL))
$(info INSTALLER_NAME     : $(INSTALLER_NAME))
$(info INSTALLER_TAG_V    : $(INSTALLER_TAG_V))
$(info CPU_HARDWARE       : $(shell uname -m))
$(info DOCKER_EMULATION   : $(DOCKER_EMULATION))
$(info TWILIO_ACCOUNT_NAME: $(shell twilio api:core:accounts:fetch --sid=$(TWILIO_ACCOUNT_SID) --no-header --properties=friendlyName))
$(info TWILIO_ACCOUNT_SID : $(TWILIO_ACCOUNT_SID))
$(info TWILIO_AUTH_TOKEN  : $(shell echo $(TWILIO_AUTH_TOKEN) | sed 's/./*/g'))
$(info SERVICE_NAME       : $(SERVICE_NAME))
$(info ================================================================================)


targets:
	@echo ----- avaiable make targets:
	@grep '^[A-Za-z0-9\-]*:' Makefile | cut -d ':' -f 1 | sort


check-prerequisites:
	$(eval DOCKER := $(shell which docker))
	@if [[ -z "$(DOCKER)" ]]; then \
	  echo prerequisite: missing docker, please install docker desktop !!!; \
	else \
	  echo "prerequisite: " `docker --version`; \
	fi
	@[[ ! -z "$(DOCKER)" ]]

	$(eval TWILIOCLI := $(shell which twilio))
	@if [[ -z "$(TWILIOCLI)" ]]; then \
	  echo prerequisite: missing twilio cli, please install via 'brew tap twilio/brew && brew install twilio'!!!; \
	else \
	  echo "prerequisite: " `twilio --version`; \
	fi
	@[[ ! -z "$(TWILIOCLI)" ]]

	$(eval SERVERLESS_PLUGIN := $(shell twilio plugins | grep serverless))
	@if [[ -z "$(SERVERLESS_PLUGIN)" ]]; then \
	  echo prerequisite: missing twilio serverless plugin, please install !!!; \
	else \
	  echo "prerequisite: " `twilio plugins | grep serverless`; \
	fi
	@[[ ! -z "$(SERVERLESS_PLUGIN)" ]]

	$(eval JQ := $(shell which jq))
	@if [[ -z "$(JQ)" ]]; then \
	  echo prerequisite: missing jq, please install via 'brew install jq'!!!; \
	else \
	  echo "prerequisite: " `jq --version`; \
	fi
	@[[ ! -z "$(JQ)" ]]

	$(eval XQ := $(shell which xq))
	@if [[ -z "$(XQ)" ]]; then \
	  echo prerequisite: missing xq, please install via 'brew install python-yq'!!!; \
	else \
	  echo "prerequisite: " `xq --version`; \
	fi
	@[[ ! -z "$(XQ)" ]]

	$(eval NGROK := $(shell which ngrok))
	@if [[ -z "$(NGROK)" ]]; then \
	  echo prerequisite: missing ngrok, please install!!!; \
	else \
	  echo "prerequisite: " `ngrok --version`; \
	fi
	@[[ ! -z "$(NGROK)" ]]


installer-build-github:
	docker build --tag $(INSTALLER_TAG_V) --tag $(INSTALLER_TAG_L) $(DOCKER_EMULATION) --no-cache $(GIT_REPO_URL)#main


installer-build-local:
	docker system prune --force
	docker volume prune --force
	docker build --tag $(INSTALLER_TAG_V) --tag $(INSTALLER_TAG_L) $(DOCKER_EMULATION) --no-cache .


installer-push:
	docker login --username twiliohls
	docker push $(INSTALLER_TAG_V)
	docker push $(INSTALLER_TAG_L)
	docker logout
	open -a "Google Chrome" https://hub.docker.com/r/twiliohls/$(INSTALLER_NAME)


installer-run:
	docker run --name $(INSTALLER_NAME) --rm --publish 3000:3000 $(DOCKER_EMULATION) \
	--volume /var/run/docker.sock:/var/run/docker.sock \
	--env ACCOUNT_SID=$(TWILIO_ACCOUNT_SID) --env AUTH_TOKEN=$(TWILIO_AUTH_TOKEN) \
	--interactive --tty $(INSTALLER_TAG_V)


installer-open:
	while [[ -z $(curl --silent --head http://localhost:3000/installer/index.html) ]]; do \
      sleep 2 \
      echo "installer not up yet..." \
    done

	open -a "Google Chrome" http://localhost:3000/installer/index.html


redeploy-mirth-channels:
# for re-deploying failed mirth channel deployments
# . if patient-appointment-management studio flow is redeployed, run this as FLOW_SID would have changed
	cd assets/ehr; \
	./mirth-deploy-channels.private.sh


run-serverless:
	npm install
	@if [[ ! -f .env.localhost ]]; then \
      echo ".env.localhost needs to be copied from .env and value set!!! aborting..."; \
    fi
	@[[ -f .env.localhost ]]
	twilio serverless:start --env=.env.localhost --load-local-env


run-ngrok:
	@if [[ -z "$(NGROK_HOSTNAME)" ]]; then \
  	  echo 'Usage: make run-ngrok NGROK_HOSTNAME=your-ngrok-hostname e.g., bochoi.ngrok.io'; \
	fi
	@[[ ! -z "$(NGROK_HOSTNAME)" ]]

	ngrok http --region=us --hostname=$(NGROK_HOSTNAME) 8661


openemr-adjust-appointment-dates:
	cd assets/ehr && ./openemr-adjust-appointment-dates.private.sh


openemr-disable-triggers:
	docker exec -i openemr_db mysql --user=root --password=root openemr < assets/ehr/openemr/drop_all_triggers.sql


openemr-enable-triggers:
	docker exec --interactive openemr_db mysql --user=root --password=root openemr < assets/ehr/openemr/create_appointment_insert_trigger.sql
	docker exec --interactive openemr_db mysql --user=root --password=root openemr < assets/ehr/openemr/create_appointment_update_trigger.sql
	docker exec --interactive openemr_db mysql --user=root --password=root openemr < assets/ehr/openemr/create_patient_update_trigger.sql


openemr-backup-volumes:
	@if [[ -z "$(BACKUP_NAME)" ]]; then \
  	  echo 'Usage: make openemr-backup-volumes BACKUP_NAME=your-backup-name'; \
	fi
	@[[ ! -z "$(BACKUP_NAME)" ]]
	cd assets/ehr/openemr && ./openemr-backup-volumes.sh $(BACKUP_NAME)


openemr-restore-volumes:
	@if [[ -z "$(BACKUP_NAME)" ]]; then \
  	  echo 'Usage: make openemr-restore-volumes BACKUP_NAME=your-backup-name'; \
	fi
	@[[ ! -z "$(BACKUP_NAME)" ]]
	cd assets/ehr && ./openemr-restore-volumes.sh $(BACKUP_NAME)


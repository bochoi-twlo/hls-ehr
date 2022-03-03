# --------------------------------------------------------------------------------------------------------------
# FOR DEVELOPER USE ONLY!!!
# --------------------------------------------------------------------------------------------------------------
APPLICATION_NAME := $(shell basename `pwd`)

ifdef ACCOUNT_SID
$(info Twilio ACCOUNT_SID=$(ACCOUNT_SID))
else
$(info Twilio ACCOUNT_SID environment variable is not set)
$(info Lookup your "ACCOUNT SID" at https://console.twilio.com/)
ACCOUNT_SID := $(shell read -p "Enter ACCOUNT_SID=" input && echo $$input)
$(info )
endif

ifdef AUTH_TOKEN
$(info Twilio AUTH_TOKEN=$(shell echo $(AUTH_TOKEN) | sed 's/./*/g'))
else
$(info Twilio Account SID environment variable is not set)
$(info Lookup your "AUTH TOKEN" at https://console.twilio.com/)
AUTH_TOKEN := $(shell read -p "Enter AUTH_TOKEN=" input && echo $$input)
$(info )
endif


USERNAME := $(shell whoami)
S3BUCKET_ARTIFACTS := twlo-hls-artifacts

targets:
	@echo ---------- $@
	@grep '^[A-Za-z0-9\-]*:' Makefile | cut -d ':' -f 1 | sort


installer-build-github:
	docker build --tag hls-ehr-installer --no-cache https://github.com/bochoi-twlo/hls-ehr.git#main

installer-build-local:
	docker build --tag hls-ehr-installer --no-cache .

installer-run:
	docker run --name hls-ehr-installer --rm --publish 3000:3000  \
	--volume /var/run/docker.sock:/var/run/docker.sock \
	--env ACCOUNT_SID=$(ACCOUNT_SID) --env AUTH_TOKEN=$(AUTH_TOKEN) \
	--interactive --tty hls-ehr-installer

installer-open:
	while [[ -z $(curl --silent --head http://localhost:3000/installer/index.html) ]]; do \
      sleep 2 \
      echo "installer not up yet..." \
    done

	open -a "Google Chrome" http://localhost:3000/installer/index.html

deploy-project:
	@echo ---------- $@
	$(eval ZIPFILE := project.zip)
	if [[ -f $(ZIPFILE) ]]; then rm $(ZIPFILE); fi
	aws s3 cp s3://$(S3BUCKET_ARTIFACTS)/appointments/$(ZIPFILE) $(ZIPFILE) --sse

	unzip $(ZIPFILE)

	rm $(ZIPFILE)


deploy-service:
	@echo ---------- $@
	twilio serverless:deploy



deploy-flow:
	@echo ---------- $@
	@if [ -z $(NGROK_URL) ]; then \
  		echo "missing NGROK_URL environment variable!!!"; \
  		echo "Usage: make $@ NGROK_URL=https://xxxxx.ngrok.io"; \
  	else \
		pushd assets; \
		./deploy-flow-template.sh $(NGROK_URL); \
		popd; \
	fi;


deploy-openemr:
	@echo ---------- $@
	pushd emr; \
	./deploy-openemr-volumes.sh; \
	popd;


deploy-mirth:
	@echo ---------- $@
	pushd emr; \
	./deploy-mirth-channels.sh; \
	popd;

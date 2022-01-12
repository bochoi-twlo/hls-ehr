#
# to be used by demo developer
#

ifndef TWILIO_ACCOUNT_SID
$(error 'TWILIO_ACCOUNT_SID enviroment variable not defined')
endif
ifndef TWILIO_AUTH_TOKEN
$(error 'TWILIO_AUTH_TOKEN enviroment variable not defined')
endif

USERNAME := $(shell whoami)
S3BUCKET_ARTIFACTS := twlo-hls-artifacts

targets:
	@echo ---------- $@
	@grep '^[A-Za-z0-9\-]*:' Makefile | cut -d ':' -f 1 | sort


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

# --------------------------------------------------------------------------------
# Dockerfile for local installer
# --------------------------------------------------------------------------------
FROM twilio/twilio-cli:3.3.0

# install docker (-in-docker) for debian OS
# https://docs.docker.com/engine/install/debian/#install-using-the-repository
RUN apt-get update
RUN apt-get -y install \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update
RUN apt-get -y install docker-ce docker-ce-cli containerd.io

# install docker compose
# https://docs.docker.com/compose/install/#install-compose-on-linux-systems
RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose
RUN ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

RUN apt install jq -y

RUN apt install python-pip -y
RUN pip install yq

# install pre-requisites
RUN twilio plugins:install @twilio-labs/plugin-serverless

WORKDIR /hls-ehr

# copy github files needed for running locally
COPY package.json .env /hls-ehr/
COPY docker-compose.yml /hls-ehr/
COPY assets /hls-ehr/assets
COPY functions /hls-ehr/functions

# install node dependencies in package.json
RUN npm install

# expose default port for running locally
EXPOSE 3000

# use --load-local-dev to access environment variables passed in from docker run command
CMD ["twilio", "serverless:start", "--load-local-env"]

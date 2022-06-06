#!/bin/bash
set -e

function output {
  echo 'openemr-apply-sso-hack.sh:' $1
}

# --------------------------------------------------------------------------------
# script to apply sso hack changes
# --------------------------------------------------------------------------------
# check hls-ehr
if [ "$(docker ps --all | grep openemr_app)" ]; then
  output 'found hls-ehr docker compose stack. proceeding ...'
else
  output 'no hls-ehr docker compose stack!!! exiting ...'
  exit 1
fi

# ---------- main execution ----------------------------------------------------------------------

output 'applying sso hack changes ...'
if [ "$(docker ps | grep openemr_app)" ]; then
  # currently running
  docker stop openemr_app

  docker cp openemr/ssoHack/hack/var/www/localhost/htdocs/openemr/interface/globals.php                   openemr_app:/var/www/localhost/htdocs/openemr/interface/globals.php
  docker cp openemr/ssoHack/hack/var/www/localhost/htdocs/openemr/interface/main/tabs/main.php            openemr_app:/var/www/localhost/htdocs/openemr/interface/main/tabs/main.php
  docker cp openemr/ssoHack/hack/var/www/localhost/htdocs/openemr/interface/main/tabs/js/frame_proxies.js openemr_app:/var/www/localhost/htdocs/openemr/interface/main/tabs/js/frame_proxies.js
  docker cp openemr/ssoHack/hack/var/www/localhost/htdocs/openemr/src/Common/Csrf/CsrfUtils.php           openemr_app:/var/www/localhost/htdocs/openemr/src/Common/Csrf/CsrfUtils.php

  docker start openemr_app
else
  # currently not running
  docker cp openemr/ssoHack/hack/var/www/localhost/htdocs/openemr/interface/globals.php                   openemr_app:/var/www/localhost/htdocs/openemr/interface/globals.php
  docker cp openemr/ssoHack/hack/var/www/localhost/htdocs/openemr/interface/main/tabs/main.php            openemr_app:/var/www/localhost/htdocs/openemr/interface/main/tabs/main.php
  docker cp openemr/ssoHack/hack/var/www/localhost/htdocs/openemr/interface/main/tabs/js/frame_proxies.js openemr_app:/var/www/localhost/htdocs/openemr/interface/main/tabs/js/frame_proxies.js
  docker cp openemr/ssoHack/hack/var/www/localhost/htdocs/openemr/src/Common/Csrf/CsrfUtils.php           openemr_app:/var/www/localhost/htdocs/openemr/src/Common/Csrf/CsrfUtils.php
fi

output 'complete'

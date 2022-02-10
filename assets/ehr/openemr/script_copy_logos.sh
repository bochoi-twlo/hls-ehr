docker cp ../images/logo-owl-health.png openemr_app:/var/www/localhost/htdocs/openemr/sites/default/images

docker cp ../images/logo-twilio-red.png openemr_app:/var/www/localhost/htdocs/openemr/sites/default/images

docker exec openemr_app cp /var/www/localhost/htdocs/openemr/sites/default/images/logo-twilio-red-150x69.png /var/www/localhost/htdocs/openemr/sites/default/images/logo_2.
png

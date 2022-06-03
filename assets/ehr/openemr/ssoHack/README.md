# SSO Hack for OpenEMR inside Flex

## File Changed in OpenEMR

The following 4 files have been changed to simulate SSO & auto selecting patient.
The `original` folder contains original files from the openEMR distribution
while `hack` folder contains the changed files

```shell
var/www/localhost/htdocs/openemr/src/Common/Csrf/CsrfUtils.php
var/www/localhost/htdocs/openemr/interface/globals.php
var/www/localhost/htdocs/openemr/interface/main/tabs/main.php
var/www/localhost/htdocs/openemr/interface/main/tabs/js/frame_proxies.js
```

### Manually applying changes

Manually applying sso Hack on top of deployed openEMR
by executing the following from the `ssoHack` directory

```shell
docker container stop openemr_app
docker cp hack/var/www/localhost/htdocs/openemr/interface/globals.php                   openemr_app:/var/www/localhost/htdocs/openemr/interface/globals.php
docker cp hack/var/www/localhost/htdocs/openemr/interface/main/tabs/main.php            openemr_app:/var/www/localhost/htdocs/openemr/interface/main/tabs/main.php
docker cp hack/var/www/localhost/htdocs/openemr/interface/main/tabs/js/frame_proxies.js openemr_app:/var/www/localhost/htdocs/openemr/interface/main/tabs/js/frame_proxies.js
docker cp hack/var/www/localhost/htdocs/openemr/src/Common/Csrf/CsrfUtils.php           openemr_app:/var/www/localhost/htdocs/openemr/src/Common/Csrf/CsrfUtils.php
docker container start openemr_app
```


## Changes to Flex Plugin

In the Flex plug-in, `src/components/CustomPanel2/Panes/AppointmentSchedulingPane/AppointmentSchedulingPane.tsx`
embeds openEMR inside an iframe

Prior to the SSO Hack, iframe looks like:

```html
<iframe className="open-emr"  src="http://localhost/interface/login/login.php?site=default" allow="fullscreen"/>
```

After the SSO Hack is deployed to openEMR, iframe looks like

```html
<iframe className="open-emr" src="http://localhost/interface/main/main_screen.php?auth=login&site=default" allow="fullscreen"/>      </div>
```

where the login is hard-coded to `admin/pass` user.

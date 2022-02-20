#!/bin/sh

chmod +w interface/login/login.php
sed -i -e 's/target="_top"/target="_self"/'  interface/login/login.php

chmod +w src/Common/Session/SessionUtil.php
sed -i -e 's/use_cookie_samesite = "Strict"/use_cookie_samesite = "None"/' src/Common/Session/SessionUtil.php
sed -i -e 's/use_cookie_secure = false/use_cookie_secure = true/' src/Common/Session/SessionUtil.php

chmod +w library/js/utility.js
sed -i -e 's/top.i18next/self.i18next/g' library/js/utility.js
sed -i -e 's/top.webroot_url/parent.webroot_url/' library/js/utility.js

chmod +w library/auth.inc
sed -i -e 's/w.top/w.self/g' library/auth.inc

chmod +w interface/main/tabs/js/tabs_view_model.js
sed -i -e 's/top.restoreSession/self.restoreSession/g' interface/main/tabs/js/tabs_view_model.js

chmod +w interface/main/tabs/js/user_data_view_model.js
sed -i -e 's/top.restoreSession/self.restoreSession/' interface/main/tabs/js/user_data_view_model.js

chmod +w interface/main/finder/dynamic_finder.php
sed -i -e 's/top.restoreSession/parent.restoreSession/g' interface/main/finder/dynamic_finder.php
sed -i -e 's/top.RTop/parent.RTop/g' interface/main/finder/dynamic_finder.php

chmod +w interface/patient_file/summary/demographics.php
sed -i -e 's/top.restoreSession/parent.restoreSession/g' interface/patient_file/summary/demographics.php

chmod +w library/dialog.js
sed -i -e 's/top.restoreSession/parent.restoreSession/g' library/dialog.js
sed -i -e 's/top.set_opener/parent.set_opener/g' library/dialog.js
sed -i -e 's/top.opener_list/parent.opener_list/g' library/dialog.js
sed -i -e 's/top : window/parent : window/g' library/dialog.js

chmod +w interface/main/tabs/js/dialog_utils.js
sed -i -e 's/top.opener_list/self.opener_list/g' interface/main/tabs/js/dialog_utils.js

chmod +w interface/main/calendar/modules/PostCalendar/pntemplates/default/views/day/ajax_template.html
sed -i -e 's/top.restoreSession/parent.restoreSession/g' interface/main/calendar/modules/PostCalendar/pntemplates/default/views/day/ajax_template.html

chmod +w interface/main/calendar/modules/PostCalendar/pntemplates/default/views/week/ajax_template.html
sed -i -e 's/top.restoreSession/parent.restoreSession/g' interface/main/calendar/modules/PostCalendar/pntemplates/default/views/week/ajax_template.html

chmod +w interface/main/calendar/modules/PostCalendar/pntemplates/default/views/month/ajax_template.html
sed -i -e 's/top.restoreSession/parent.restoreSession/g' interface/main/calendar/modules/PostCalendar/pntemplates/default/views/month/ajax_template.html

chmod +w interface/main/tabs/timeout_iframe.php
sed -i -e 's/top.restoreSession/parent.restoreSession/g' interface/main/tabs/timeout_iframe.php

chmod +w interface/main/dated_reminders/dated_reminders.php
sed -i -e 's/top.restoreSession/parent.restoreSession/g' interface/main/dated_reminders/dated_reminders.php

chmod +w interface/main/tabs/js/include_opener.js
sed -i -e 's/top.get_opener/parent.get_opener/g' interface/main/tabs/js/include_opener.js
sed -i -e 's/wframe = top/wframe = parent/g' interface/main/tabs/js/include_opener.js
sed -i -e 's/dialogModal = top/dialogModal = parent/g' interface/main/tabs/js/include_opener.js

chmod +w interface/main/calendar/add_edit_event.php
sed -i -e 's/top.restoreSession/parent.restoreSession/g' interface/main/calendar/add_edit_event.php

chmod +w library/validation/validation_script.js.php
sed -i -e 's/top.restoreSession/parent.restoreSession/' library/validation/validation_script.js.php

chmod +w interface/main/calendar/find_appt_popup.php
sed -i -e 's/top.restoreSession/parent.restoreSession/g' interface/main/calendar/find_appt_popup.php
# 2 more replaced - chec!!!

#chmod +w interface/main/messages/messages.php
#sed -i -e 's/top.restoreSession/restoreSession/g' interface/main/messages/messages.php


--
-- main SQL
--
-- Note that mirth channel export via REST strips newline character, so ensure proper spacing
--
update openemr.openemr_postcalendar_events
  set pc_apptstatus = case
    when ${event_type} = 'Confirm' then 'SMS'
    when ${event_type} = 'Cancel'  then 'x'
  end
  where pc_eid = ${appointment_id}

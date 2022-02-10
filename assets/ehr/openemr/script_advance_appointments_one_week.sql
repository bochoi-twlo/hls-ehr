update openemr.openemr_postcalendar_events
set pc_eventDate = date_add(pc_eventDate, interval 7 day);

update openemr.openemr_postcalendar_events
set pc_endDate = date_add(pc_endDate, interval 7 day)
where pc_endDate <> '0000-00-00';

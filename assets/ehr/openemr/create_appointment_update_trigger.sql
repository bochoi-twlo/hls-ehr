
drop trigger if exists openemr.appointment_update;

delimiter //


create trigger openemr.appointment_update
after update on openemr.openemr_postcalendar_events
for each row
begin
  declare v_event_type varchar(19);

  if     new.pc_apptstatus = 'x' and old.pc_apptstatus <> 'x'      then set v_event_type = 'CANCELED';
  elseif new.pc_apptstatus = '%' and old.pc_apptstatus <> '%'      then set v_event_type = 'CANCELED';
  elseif new.pc_apptstatus = 'SMS' and old.pc_apptstatus <> 'SMS'  then set v_event_type = 'CONFIRMED';
  elseif new.pc_apptstatus = '?'   and old.pc_apptstatus <> '?'    then set v_event_type = 'NOSHOW';
  elseif new.pc_eventDate <> old.pc_eventDate
      or new.pc_startTime <> old.pc_startTime                      then set v_event_type = 'RESCHEDULED';
  elseif new.pc_aid       <> old.pc_aid
      or new.pc_facility  <> old.pc_facility                       then set v_event_type = 'MODIFIED';
  else   set v_event_type = 'IGNORED-EMR-EVENT';
  end if;

  if v_event_type <> 'IGNORED-EMR-EVENT' then
    insert into mirth.appointment_events (
      event_flow
    , event_status
    , event_type
    , event_utc
    , appointment_id
    , appointment_start_ltz
    , appointment_end_ltz
    , appointment_location
    , provider_id
    , provider_first_name
    , provider_last_name
    , provider_callback_phone
    , patient_id
    , patient_first_name
    , patient_last_name
    , patient_phone
    )
    select
      'SEND'                                        as event_flow
    , 'QUEUED'                                      as event_status
    , v_event_type                                  as event_type
    , current_timestamp                             as event_utc
    , cast(ope.pc_eid as char)                      as appointment_id
    , timestamp(ope.pc_eventDate, ope.pc_startTime) as appointment_start_ltz
    , timestamp(ope.pc_eventDate, ope.pc_endTime)   as appointment_end_ltz
    , f.name                                        as appointment_location
    , u.username                                    as provider_id
    , u.fname                                       as provider_first_name
    , u.lname                                       as provider_last_name
    , f.phone                                       as provider_callback_phone
    , cast(p.id as char)                            as patient_id
    , p.fname                                       as patient_first_name
    , p.lname                                       as patient_last_name
    , p.phone_cell                                  as patient_phone
    from openemr.openemr_postcalendar_events as ope
    join openemr.users                       as u   on u.id = ope.pc_aid        -- provider
    join openemr.facility                    as f   on f.id = ope.pc_facility   -- location
    join openemr.patient_data                as p   on p.id = ope.pc_pid        -- patient
    where ope.pc_aid      is not null -- has provider
      and ope.pc_pid      is not null -- has patient
      and ope.pc_facility is not null -- has location
      and(p.hipaa_allowsms = 'YES' or p.hipaa_voice = 'YES') -- limit to optin
      and ope.pc_eid = new.pc_eid;
  end if;

end; //

delimiter ;

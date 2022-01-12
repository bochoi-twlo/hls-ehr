

drop trigger if exists openemr.patient_update;

delimiter //


create trigger openemr.patient_update
after update on openemr.patient_data
for each row
begin
  declare v_event_type varchar(19);

  if     new.hipaa_allowsms <> old.hipaa_allowsms and new.hipaa_allowsms = 'NO' then set v_event_type = 'OPTED-OUT';
  elseif new.hipaa_allowsms = 'YES'               and old.hipaa_allowsms = 'NO' then set v_event_type = 'OPTED-IN';
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
      'SEND'             as event_flow
    , 'QUEUED'           as event_status
    , v_event_type       as event_type
    , current_timestamp  as event_utc
    , 'unspecified'      as appointment_id
    , '9999-12-31'       as appointment_start_ltz
    , '9999-12-31'       as appointment_end_ltz
    , 'unspecified'      as appointment_location
    , 'unspecified'      as provider_id
    , 'unspecified'      as provider_first_name
    , 'unspecified'      as provider_last_name
    , 'unspecified'      as provider_callback_phone
    , cast(p.id as char) as patient_id
    , p.fname            as patient_first_name
    , p.lname            as patient_last_name
    , p.phone_cell       as patient_phone
    from openemr.patient_data
    where p.id = old.id;
  end if;

end; //

delimiter ;


--
-- post-process SQL
--
-- Note that mirth channel export via REST strips newline character, so ensure proper spacing
--
update mirth.appointment_events set event_status = 'PROCESSED' where event_id = ${event_id}

--
-- main SQL
--
-- Note that mirth channel export via REST strips newline character, so ensure proper spacing
--
select
  event_id
, date_format(event_utc, '%Y%m%d%H%i%s') as MSH7
, case event_type
    when 'BOOKED'      then 'SIU^S12'
    when 'CANCELED'    then 'SIU^S15'
    when 'CONFIRMED'   then 'SIU^S14'
    when 'MODIFIED'    then 'SIU^S14'
    when 'RESCHEDULED' then 'SIU^S13'
    when 'NOSHOW'      then 'SIU^S26'
    when 'OPTED-OUT'   then 'SIU^S14'
    when 'OPTED-IN'    then 'SIU^S14'
    else null
  end as MSH9
, event_type as SCH25
, event_id                                           as MSH10
, appointment_id                                     as SCH1
, appointment_id                                     as SCH5
, timestampdiff(MINUTE, appointment_start_ltz, appointment_end_ltz) as SCH9
, timestampdiff(MINUTE, appointment_start_ltz, appointment_end_ltz) as SCH11_3
, date_format(appointment_start_ltz, '%Y%m%d%H%i%s') as SCH11_4
, date_format(appointment_end_ltz,   '%Y%m%d%H%i%s') as SCH11_5
, provider_id                                        as SCH12_1
, provider_first_name                                as SCH12_3
, provider_last_name                                 as SCH12_2
, provider_callback_phone                            as SCH13
, patient_id                                         as PID3
, patient_first_name                                 as PID5_2
, patient_last_name                                  as PID5_1
, patient_phone                                      as PID13_1
, appointment_location                               as AIL3_1
, appointment_location                               as AIL3_4
 from mirth.appointment_events
 where event_flow   = 'SEND'
   and event_status = 'QUEUED'
   and event_type  in ('BOOKED', 'RESCHEDULED', 'MODIFIED', 'CANCELED', 'NOSHOW', 'CONFIRMED', 'OPTED-OUT', 'OPTED-IN')

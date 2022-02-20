-- ################################################################################
-- mirth companion schema/tables
--
-- mirth.appointment_event will collect EMR appointment events for outbound IE
-- channel to pick up.
--
-- event_flow: SEND for outbound to Twilio, RECEIVE for inbound from Twilio. RECEIVE not used currently
-- event_status: transitions from QUEUED -> PROCESSED if successful, ERRORED otherwise
-- event_type: valid outbound appointment event initiated from EMR
-- ################################################################################

create schema if not exists mirth;

drop table if exists mirth.appointment_events;

create table if not exists mirth.appointment_events (
  event_id                bigint      not null auto_increment
, event_flow              varchar(9)  not null comment 'SEND|RECEIVE'
, event_status            varchar(9)  not null comment 'QUEUED|PROCESSED|ERRORED'
, event_type              varchar(11) not null comment 'BOOKED|CANCELED|CONFIRMED|MODIFIED|RESCHEDULED|NOSHOW|OPTED-OUT|OPTED-IN'
, event_utc               datetime    not null
, create_utc              datetime    not null default current_timestamp
, appointment_id          varchar(99) not null
, appointment_start_ltz   datetime
, appointment_end_ltz     datetime
, appointment_location    varchar(99)
, provider_id             varchar(19)
, provider_first_name     varchar(99)
, provider_last_name      varchar(99)
, provider_callback_phone varchar(19)
, patient_id              varchar(99) not null
, patient_first_name      varchar(99)
, patient_last_name       varchar(99)
, patient_phone           varchar(99)
, primary key (event_id)
) ENGINE=InnoDB default CHARSET=utf8mb4
;

CREATE DATABASE ev_charging;
CREATE SCHEMA IF NOT EXISTS ev;
DROP TABLE IF EXISTS ev.sessions_raw CASCADE;

CREATE TABLE ev.sessions_raw (
    station_name    text,
    port_number     text,
    port_type       text,
    plug_type       text,
    start_date      text,
    end_date        text,
    total_duration  text,
    charging_time   text,
    energy_kwh      text,
    ghg_kg          text,
    gasoline_gal    text,
    fee             text,
    ended_by        text,
    user_id         text,
    latitude        text,
    longitude       text
);


SELECT COUNT(*) FROM ev.sessions_raw;
SELECT * FROM ev.sessions_raw LIMIT 5;

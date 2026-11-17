-- one clean row per charging session


DROP VIEW IF EXISTS ev.sessions CASCADE;

CREATE VIEW ev.sessions AS
WITH typed AS (
    SELECT
        trim(station_name)                                         AS station_name,
        -- "PALO ALTO CA / HAMILTON #1" -> "Hamilton", "RINCONADA LIB 2" -> "Rinconada Library"
        CASE initcap(trim(regexp_replace(split_part(station_name, '/', 2), '#?\s*\d+\s*$', '')))
            WHEN 'Mpl'           THEN 'Mitchell Park Library'
            WHEN 'Rinconada Lib' THEN 'Rinconada Library'
            ELSE initcap(trim(regexp_replace(split_part(station_name, '/', 2), '#?\s*\d+\s*$', '')))
        END                                                        AS site,
        trim(station_name) || ' / Port ' || coalesce(nullif(trim(port_number), ''), '1')
                                                                   AS port_id,
        port_type,
        plug_type,
        -- some rows store dates as Excel serial numbers (e.g. 42845.81041 = 20 Apr 2017 19:27)
        CASE WHEN trim(start_date) ~ '^\d+(\.\d+)?$'
             THEN date_trunc('minute', timestamp '1899-12-30' + trim(start_date)::numeric * interval '1 day' + interval '30 seconds')
             ELSE to_timestamp(trim(start_date), 'MM/DD/YYYY HH24:MI')::timestamp
        END                                                        AS start_ts,
        CASE WHEN trim(end_date) ~ '^\d+(\.\d+)?$'
             THEN date_trunc('minute', timestamp '1899-12-30' + trim(end_date)::numeric * interval '1 day' + interval '30 seconds')
             ELSE to_timestamp(trim(end_date), 'MM/DD/YYYY HH24:MI')::timestamp
        END                                                        AS end_ts,
        -- durations can also be Excel fractions of a day (0.125 = 3 hours)
        CASE WHEN trim(total_duration) ~ '^\d+(\.\d+)?$'
             THEN trim(total_duration)::numeric * 24
             ELSE extract(epoch FROM trim(total_duration)::interval) / 3600.0
        END                                                        AS plugged_hours,
        CASE WHEN trim(charging_time) ~ '^\d+(\.\d+)?$'
             THEN trim(charging_time)::numeric * 24
             ELSE extract(epoch FROM trim(charging_time)::interval) / 3600.0
        END                                                        AS charging_hours,
        replace(energy_kwh,   ',', '')::numeric                    AS energy_kwh,
        replace(ghg_kg,       ',', '')::numeric                    AS ghg_kg,
        replace(gasoline_gal, ',', '')::numeric                    AS gasoline_gal,
        coalesce(nullif(replace(fee, ',', ''), '')::numeric, 0)    AS fee_usd,
        ended_by,
        nullif(trim(user_id), '')                                  AS user_id,
        nullif(latitude,  '')::numeric                             AS latitude,
        nullif(longitude, '')::numeric                             AS longitude
    FROM ev.sessions_raw
    WHERE start_date IS NOT NULL
      AND total_duration IS NOT NULL
),
cleaned AS (
    SELECT
        *,
        date_trunc('month', start_ts)::date AS start_month
    FROM typed
    WHERE energy_kwh > 0              -- plugged in but no energy = not a real charge
      AND energy_kwh <= 150           -- a few meter glitches report impossible kWh
      AND plugged_hours > 0
      AND plugged_hours <= 72         -- over 3 days is a parked car, not a charging session
)
SELECT
    row_number() OVER (ORDER BY start_ts, port_id)       AS session_id,
    station_name,
    site,
    port_id,
    port_type,
    plug_type,
    start_ts,
    end_ts,
    start_month,
    extract(year FROM start_ts)::int                     AS start_year,
    extract(hour FROM start_ts)::int                     AS start_hour,
    extract(isodow FROM start_ts)::int                   AS weekday_num,   -- 1 = Mon
    to_char(start_ts, 'Dy')                              AS weekday_name,
    round(plugged_hours, 3)                              AS plugged_hours,
    round(least(charging_hours, plugged_hours), 3)       AS charging_hours,
    round(greatest(plugged_hours - charging_hours, 0), 3) AS idle_hours,
    energy_kwh,
    ghg_kg,
    gasoline_gal,
    fee_usd,
    ended_by,
    user_id,
    latitude,
    longitude,
    -- hours this port was available in the month, shared across its sessions that month.
    -- SUM() of this over any port / site / month / year selection = available port-hours.
    round(
        extract(day FROM (start_month + interval '1 month' - start_month)) * 24.0
        / count(*) OVER (PARTITION BY port_id, start_month)
    , 4)                                                 AS available_hours_share
FROM cleaned;
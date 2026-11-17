-- 01_extract_duckdb.sql
-- run in DuckDB from the project folder
-- keeps the 16 columns the dashboard needs and writes a smaller CSV for pgAdmin
COPY (
    SELECT
        "Station Name"               AS station_name,
        "Port Number"                AS port_number,
        "Port Type"                  AS port_type,
        "Plug Type"                  AS plug_type,
        "Start Date"                 AS start_date,
        "End Date"                   AS end_date,
        "Total Duration (hh:mm:ss)"  AS total_duration,
        "Charging Time (hh:mm:ss)"   AS charging_time,
        "Energy (kWh)"               AS energy_kwh,
        "GHG Savings (kg)"           AS ghg_kg,
        "Gasoline Savings (gallons)" AS gasoline_gal,
        "Fee"                        AS fee,
        "Ended By"                   AS ended_by,
        "User ID"                    AS user_id,
        "Latitude"                   AS latitude,
        "Longitude"                  AS longitude
    FROM read_csv('data/EVChargingStationUsage.csv',
                  all_varchar = true, header = true, ignore_errors = true)
) TO 'data/ev_sessions.csv' (HEADER, DELIMITER ',');

SELECT COUNT(*) FROM 'data/ev_sessions.csv';

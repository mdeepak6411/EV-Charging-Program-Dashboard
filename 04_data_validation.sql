DROP TABLE IF EXISTS ev.sessions_export;
CREATE TABLE ev.sessions_export AS
SELECT * FROM ev.sessions ORDER BY session_id;

SELECT site,
       count(*) AS sessions,
       round(100 * sum(idle_hours) / sum(plugged_hours), 1) AS idle_pct,
       round(100.0 * count(*) FILTER (WHERE idle_hours > 1) / count(*), 1) AS pct_sessions_idle_over_1h
FROM ev.sessions
WHERE start_year = 2019
GROUP BY site
ORDER BY idle_pct DESC;


SELECT min(start_ts), max(start_ts) FROM ev.sessions;
SELECT start_year, count(*) FROM ev.sessions GROUP BY start_year ORDER BY 1;

SELECT count(*) AS sessions,
       round(sum(energy_kwh) / 1000) AS energy_mwh,
       round(100 * sum(idle_hours) / sum(plugged_hours), 1) AS idle_pct
FROM ev.sessions
WHERE start_year = 2019;

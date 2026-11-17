SELECT 'raw rows loaded' AS test,
       CASE WHEN count(*) > 250000 THEN 'PASS' ELSE 'FAIL' END AS result,
       count(*)::text AS detail
FROM ev.sessions_raw

UNION ALL
SELECT 'clean view keeps most rows',
       CASE WHEN (SELECT count(*) FROM ev.sessions) >= 0.9 * (SELECT count(*) FROM ev.sessions_raw)
            THEN 'PASS' ELSE 'FAIL' END,
       (SELECT count(*) FROM ev.sessions)::text || ' of ' || (SELECT count(*) FROM ev.sessions_raw)::text

UNION ALL
SELECT 'every start date parsed',
       CASE WHEN count(*) FILTER (WHERE start_ts IS NULL) = 0 THEN 'PASS' ELSE 'FAIL' END,
       count(*) FILTER (WHERE start_ts IS NULL)::text || ' missing'
FROM ev.sessions

UNION ALL
SELECT 'dates between 2011 and 2020',
       CASE WHEN min(start_ts) >= '2011-01-01' AND max(start_ts) < '2021-01-01' THEN 'PASS' ELSE 'FAIL' END,
       min(start_ts)::date::text || ' to ' || max(start_ts)::date::text
FROM ev.sessions

UNION ALL
SELECT 'charging time never above plugged time',
       CASE WHEN count(*) FILTER (WHERE charging_hours > plugged_hours) = 0 THEN 'PASS' ELSE 'FAIL' END,
       count(*) FILTER (WHERE charging_hours > plugged_hours)::text || ' rows'
FROM ev.sessions

UNION ALL
SELECT 'session ids unique',
       CASE WHEN count(*) = count(DISTINCT session_id) THEN 'PASS' ELSE 'FAIL' END,
       count(*)::text
FROM ev.sessions

UNION ALL
SELECT 'every session has a site',
       CASE WHEN count(*) FILTER (WHERE site IS NULL OR site = '') = 0 THEN 'PASS' ELSE 'FAIL' END,
       count(DISTINCT site)::text || ' sites'
FROM ev.sessions

UNION ALL
SELECT 'available hours add up per port-month',
       CASE WHEN max(abs(total - expected)) < 0.5 THEN 'PASS' ELSE 'FAIL' END,
       'max gap ' || round(max(abs(total - expected)), 2)::text
FROM (
    SELECT port_id, start_month,
           sum(available_hours_share) AS total,
           extract(day FROM (start_month + interval '1 month' - start_month)) * 24.0 AS expected
    FROM ev.sessions
    GROUP BY port_id, start_month
) t;

SELECT site, count(*) FROM ev.sessions GROUP BY site ORDER BY 2 DESC;


--to download
SELECT * FROM ev.sessions ORDER BY session_id;
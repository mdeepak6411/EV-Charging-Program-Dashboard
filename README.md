# EV Charging Program Dashboard

How is a public EV charging program performing, and are cars blocking chargers after they finish charging?

Built on 259,410 real charging sessions from the City of Palo Alto's public chargers (ChargePoint network), July 2011 to December 2020. The dashboard is designed for a site host, the organisation that owns the chargers: is the program used, which sites earn their place, when demand peaks, and what pricing or an idle fee would change.

**[Live dashboard on Tableau Public](https://public.tableau.com/views/EVChargingProgramDashboard/EVChargingProgram)**

![Dashboard](docs/dashboard.png)

## Key findings (2019)

| KPI | 2019 | vs 2018 |
| --- | --- | --- |
| Sessions | 47,728 | +11.5% |
| Energy delivered | 438 MWh | +21.5% |
| Port occupancy | 22.7% | +1.5 pts |
| Idle share | 12.8% | -2.0 pts |
| GHG avoided | 184 t | +21.5% |

- **Idle time is a site problem, not a network problem.** 12.8% of plugged-in time was idle across the network, but 22% at Rinconada Library. Rinconada looks busy (23.9% occupancy), yet its real charging use is closer to 18.6%.
- **A small group of regulars uses most of the chargers.** 5% of drivers (21+ visits a year) made 55% of sessions. Half of all drivers came only once and made 9%.
- **Charging was nearly free.** Drivers paid $987 in 2019. At $0.25 per kWh the same energy would have earned about $109,000.
- **What an idle fee would do.** A $2 per hour fee after a 1 hour grace period would have applied to 3,641 sessions and freed 5,463 port-hours for other drivers.
- **COVID.** Sessions fell sharply from April 2020 and had only partly recovered by December.

## How it was built

```
Raw CSV (259K sessions)
  -> DuckDB: keep 16 columns by name
  -> PostgreSQL 18: raw table -> clean view -> 8 data quality checks
  -> CSV export -> Tableau Public (one dashboard)
```

| Script | What it does |
| --- | --- |
| `sql/00_create_database.sql` | Creates the `ev_charging` database |
| `sql/01_extract_duckdb.sql` | Picks the 16 needed columns from the raw file (run in DuckDB) |
| `sql/02_raw_table.sql` | Raw table, all text, so the import never fails |
| `sql/03_sessions_view.sql` | Clean session view: types, site names, idle hours, available port-hours |
| `sql/04_dq_checks.sql` | 8 data quality tests, all must return PASS |

**SQL worth a look**

- Reads two date formats in the same column: normal text dates and Excel serial numbers (`42845.81041` = 20 Apr 2017 19:27).
- `available_hours_share` uses a window function to split each port's monthly hours across its sessions, so a plain `SUM` gives correct occupancy under any site, month or year filter.
- Cleans each station name (for example "PALO ALTO CA / HAMILTON #1") into one of 8 site names with `regexp_replace` and a small `CASE`.

**Tableau techniques**

- Report Year parameter with current vs prior year KPI tiles and coloured better / worse / flat change lines
- FIXED LOD for driver visits per year, EXCLUDE LOD for the median kWh under binning
- What-if parameters (idle fee, grace period, price per kWh)
- Filter and highlight dashboard actions

## KPI definitions

| KPI | Definition |
| --- | --- |
| Sessions | Charging sessions started in the year, excluding 0 kWh and 72h+ sessions |
| Energy delivered | Sum of kWh, in MWh |
| Port occupancy | Plugged-in hours / available port-hours (a port counts as available in months it was used) |
| Idle share | (Plugged-in hours - charging hours) / plugged-in hours |
| GHG avoided | Sum of GHG savings reported per session, in tonnes |

## How to run

1. Download "EV Charging Station Usage of California City" from Kaggle (City of Palo Alto data) into `data/`.
2. In pgAdmin, run `00_create_database.sql` on the default `postgres` database.
3. Run `01_extract_duckdb.sql` in DuckDB from the project folder.
4. In the `ev_charging` database run `02`, import `data/ev_sessions.csv` into `ev.sessions_raw`, then run `03` and `04`.
5. Export `ev.sessions` to CSV (via a table and Import/Export) and connect Tableau Public to it.

## Data

City of Palo Alto, Electric Vehicle Charging Station Usage (July 2011 to December 2020), via Kaggle. Public chargers on the ChargePoint network. This is an independent portfolio project, not affiliated with ChargePoint or the City of Palo Alto.

---

Built by Deepak Mishra | [LinkedIn](https://www.linkedin.com/in/md64) | [Tableau Public](https://public.tableau.com/app/profile/deepak.mishra6411)

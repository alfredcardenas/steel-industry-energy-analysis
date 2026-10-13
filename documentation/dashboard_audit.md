# Web Dashboard — Analytical Integrity Audit

**Date:** 2026-10-12
**Scope:** every value shown in the web dashboard (`docs/`), checked against the project's own data and files.

## Method

- **Data used:** the 35,040-row BigQuery export embedded in `tableau/Steel_Industry_Energy_Analysis.twbx`. That file has 0 duplicates and 0 nulls, and covers 2018-01-01 00:00 to 2018-12-31 23:45 (365 days).
- **Recalculation:** each metric was recomputed in Python (pandas) with the same aggregation the dashboard claims to use: `AVG`, `SUM` or Pearson `CORR`.
- **Repeatable check:** the comparison is automated in `scripts/verify_metrics.py`. Result: **79 / 79 checks passed.**
- **Tableau review:** the workbook XML was read to confirm each worksheet's aggregation. The workbook was **not** modified.
- **SQL and docs review:** the SQL files, the README and the case study were reviewed for consistency.

## Verified (match the raw data)

| Metric | Aggregation | Dashboard | Recomputed |
|---|---|---|---|
| Observations | COUNT | 35,040 | 35,040 |
| Avg. energy | AVG per interval | 27.39 kWh | 27.387 |
| Peak hour / peak hourly avg. | AVG by hour | 09:00 / 58.55 kWh | 09:00 / 58.55 |
| Hourly profile (24 values) | AVG by hour | all 24 | all match |
| Monthly consumption (12 values) | SUM by month | Jan 126,238.29 … Dec 59,436.78 | all match; sum 959,636.71 |
| Weekday / weekend | AVG per interval | 33.62 / 11.73 kWh | 33.625 / 11.732 |
| Weekday ÷ weekend | ratio of averages | 2.9× (2.87) | 2.866 |
| Load type (Light / Medium / Maximum) | AVG per interval | 8.63 / 38.45 / 59.27 kWh | 8.626 / 38.445 / 59.265 |
| % of intervals | COUNT share | 51.58 / 27.67 / 20.75 % | 51.575 / 27.671 / 20.753 |
| % of total kWh | SUM share | 16.24 / 38.84 / 44.91 % | 16.245 / 38.845 / 44.910 |
| Avg. lagging reactive power by load | AVG | 7.00 / 14.41 / 26.19 kVarh | match |
| Avg. CO₂ by load | AVG | 0.0026 / 0.0167 / 0.0269 tCO₂ | match |
| r, usage vs lagging reactive power | CORR, all intervals | 0.896 | 0.8961 |
| r, usage vs CO₂ | CORR, all intervals | 0.988 | 0.9882 |
| r, usage vs lagging power factor | CORR, all intervals | 0.386 | 0.3860 |

**r vs R².** 0.896, 0.988 and 0.386 are correlation coefficients (r), not R². Their R² values are 0.803, 0.976 and 0.149.

The README's "R² ≈ 0.70–0.89 across load types" is a different measure. It is R² within each load type, matching the Tableau scatter, which fits one trend line per `Load_Type`. Recomputed: Light 0.890, Medium 0.812, Maximum 0.705. **Verified.**

**Tableau aggregations confirmed.**
- Hourly, load-type and weekday/weekend sheets use `AVG(Usage_kWh)`.
- The monthly sheet uses `SUM(Usage_kWh)`.
- Both scatter plots are disaggregated (one mark per interval) with linear trend lines.

The `hour` field in the export is identical to `EXTRACT(HOUR FROM date)` and to `DIV(NSM, 3600)` for all 35,040 rows. The two methods used in different documents give the same result.

## Corrected

| Item | Issue | Fix |
|---|---|---|
| R² for CO₂ (added during this audit) | Squaring the rounded r (0.9882²) gave 0.977. The correct value is 0.976 (0.97650). | R² is now stored in `data.js`, computed from the unrounded r. |
| Data provenance note in `data.js` | Said all values came from `02_exploratory_analysis.sql`. That file does not contain the correlations or the record/energy shares. | Provenance corrected. The missing queries were added as `sql/03_dashboard_supporting_metrics.sql`. |
| Detailed Analysis cards | Showed r only, with no distinction from R². | R² line added under each r. Explanatory note updated. |

No KPI, chart value or design element of the dashboard needed a numerical correction.

## Not verified (could not be checked here)

- **Comparison with the original UCI file.** The UCI download is blocked in this environment, so the export inside the workbook could not be compared with the published source.
- **`sql/03_dashboard_supporting_metrics.sql` in BigQuery.** The query was written but not run in BigQuery. Its expected results come from the Python recalculation.
- **Tableau Desktop.** Tableau Desktop is not available here, so trend-line R² values and p-values were not read from Tableau itself. The R² values were recomputed with the same linear fit. The p-values (< 0.0001) cited in the case study were not checked.
- **Browsers.** The dashboard was rendered only in headless Chromium (desktop 1200 px and mobile 390 px, no console errors). It was not tested in Safari, Firefox or on GitHub Pages.

## Observations outside the dashboard (no changes made)

1. **Outlier count.** README and case study report 368 IQR outliers, computed with `APPROX_QUANTILES`. An exact quantile calculation (linear interpolation, the same method as BigQuery `PERCENTILE_CONT`) gives **328**. The case study already says the count is approximate. Consider reporting the exact figure or a range.
2. **CO₂ R² in the case study.** It states that a precise R² for CO₂ "wasn't independently verified". It is now verified: R² = 0.976 over all intervals (r = 0.9882).
3. **Medium + Maximum energy share.** The ANALYZE notes report 83.75%. The exact value is 83.755%, which rounds to 83.76%. 83.75 is the sum of the already-rounded shares.

-- ============================================================================
-- STEEL INDUSTRY ENERGY CONSUMPTION
-- 03_dashboard_supporting_metrics.sql
-- Source: `steel-industry-energy-analysis.steel_industry_data.steel_energy_clean`
-- Purpose: Reproduce the web dashboard metrics that 02_exploratory_analysis.sql
--          does not cover (Detailed Analysis view).
-- Expected results below were confirmed with scripts/verify_metrics.py on the
-- 35,040-row data export embedded in the Tableau workbook.
-- Note: correlations describe association, not causation.
-- ============================================================================

-- 08. FREQUENCY VS. ENERGY IMPACT BY LOAD TYPE
-- Question: Does how often a load condition occurs match how much energy it uses?
-- The CTE aggregates once per Load_Type; the window function SUM(...) OVER()
-- adds the grand total to every row so each share can be computed without
-- collapsing the groups.
-- Expected: Light 51.58% of intervals / 16.24% of kWh
--           Medium 27.67% / 38.84%
--           Maximum 20.75% / 44.91%
WITH load_agg AS (
  SELECT
    Load_Type,
    COUNT(*)       AS n_records,
    SUM(Usage_kWh) AS total_usage_kwh
  FROM `steel-industry-energy-analysis.steel_industry_data.steel_energy_clean`
  GROUP BY Load_Type
)
SELECT
  Load_Type,
  n_records,
  ROUND(100 * n_records / SUM(n_records) OVER (), 2)             AS pct_of_records,
  ROUND(total_usage_kwh, 2)                                       AS total_usage_kwh,
  ROUND(100 * total_usage_kwh / SUM(total_usage_kwh) OVER (), 2) AS pct_of_total_energy
FROM load_agg
ORDER BY total_usage_kwh DESC;

-- 09. CORRELATION (PEARSON r) ACROSS ALL INTERVALS
-- CORR() returns r, between -1 and 1. R² for a simple linear fit is r * r.
-- Expected: r = 0.8961 (R² 0.803) reactive power
--           r = 0.9882 (R² 0.976) CO2
--           r = 0.3860 (R² 0.149) power factor
SELECT
  ROUND(CORR(Usage_kWh, Lagging_Current_Reactive_Power_kVarh), 4) AS r_usage_lagging_kvarh,
  ROUND(CORR(Usage_kWh, CO2_tCO2_), 4)                            AS r_usage_co2,
  ROUND(CORR(Usage_kWh, Lagging_Current_Power_Factor), 4)         AS r_usage_lagging_pf,
  ROUND(POW(CORR(Usage_kWh, Lagging_Current_Reactive_Power_kVarh), 2), 3) AS r2_usage_lagging_kvarh,
  ROUND(POW(CORR(Usage_kWh, CO2_tCO2_), 2), 3)                            AS r2_usage_co2,
  ROUND(POW(CORR(Usage_kWh, Lagging_Current_Power_Factor), 2), 3)         AS r2_usage_lagging_pf
FROM `steel-industry-energy-analysis.steel_industry_data.steel_energy_clean`;

-- 10. R² WITHIN EACH LOAD TYPE (matches the Tableau trend lines on the
--     reactive-power scatter, which fit one line per Load_Type)
-- Expected R²: Light 0.890, Medium 0.812, Maximum 0.705
SELECT
  Load_Type,
  ROUND(POW(CORR(Usage_kWh, Lagging_Current_Reactive_Power_kVarh), 2), 3) AS r2_usage_lagging_kvarh
FROM `steel-industry-energy-analysis.steel_industry_data.steel_energy_clean`
GROUP BY Load_Type
ORDER BY r2_usage_lagging_kvarh DESC;

-- 11. AVERAGES PLOTTED IN THE DETAILED ANALYSIS VIEW
-- Expected: Light 8.63 kWh / 7.00 kVarh / 0.0026 tCO2
--           Medium 38.45 / 14.41 / 0.0167
--           Maximum 59.27 / 26.19 / 0.0269
SELECT
  Load_Type,
  ROUND(AVG(Usage_kWh), 2)                            AS avg_usage_kwh,
  ROUND(AVG(Lagging_Current_Reactive_Power_kVarh), 2) AS avg_lagging_kvarh,
  ROUND(AVG(CO2_tCO2_), 4)                            AS avg_co2_tco2
FROM `steel-industry-energy-analysis.steel_industry_data.steel_energy_clean`
GROUP BY Load_Type
ORDER BY avg_usage_kwh;

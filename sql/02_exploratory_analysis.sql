-- ============================================================================
-- STEEL INDUSTRY ENERGY CONSUMPTION
-- 02_exploratory_analysis.sql
-- Source: `steel-industry-energy-analysis.steel_industry_data.steel_energy_clean`
-- Purpose: Reproducible SQL supporting the Tableau dashboard and case study.
-- Note: Descriptive associations below should not be interpreted as causation.
-- ============================================================================

-- 01. OVERALL AVERAGE ENERGY CONSUMPTION
-- Question: What is the average energy consumption across all observations?
-- Validated result: 27.39 kWh
SELECT
  ROUND(AVG(Usage_kWh), 2) AS avg_energy_consumption_kwh
FROM `steel-industry-energy-analysis.steel_industry_data.steel_energy_clean`;

-- 02. AVERAGE ENERGY CONSUMPTION BY LOAD TYPE
-- Question: How does average consumption differ by operating load?
-- Validated: Maximum_Load 59.27; Medium_Load 38.45; Light_Load 8.63 kWh.
SELECT
  Load_Type,
  ROUND(AVG(Usage_kWh), 2) AS avg_usage_kwh
FROM `steel-industry-energy-analysis.steel_industry_data.steel_energy_clean`
GROUP BY Load_Type
ORDER BY avg_usage_kwh DESC;

-- 03. WEEKDAY VS. WEEKEND
-- Validated: Weekday 33.62 kWh; Weekend 11.73 kWh.
-- Weekday average is approximately 2.9 times the weekend average.
SELECT
  WeekStatus,
  ROUND(AVG(Usage_kWh), 2) AS avg_usage_kwh
FROM `steel-industry-energy-analysis.steel_industry_data.steel_energy_clean`
GROUP BY WeekStatus
ORDER BY avg_usage_kwh DESC;

-- 04. HOURLY ENERGY CONSUMPTION
-- EXTRACT converts the timestamp to hour-of-day; grouping then finds the
-- average for each hour. Validated peak: 09:00 = 58.55 kWh.
SELECT
  EXTRACT(HOUR FROM date) AS hour_of_day,
  ROUND(AVG(Usage_kWh), 2) AS avg_usage_kwh
FROM `steel-industry-energy-analysis.steel_industry_data.steel_energy_clean`
GROUP BY hour_of_day
ORDER BY avg_usage_kwh DESC;

-- 05. MONTHLY ENERGY CONSUMPTION
-- SUM is used because the question concerns total monthly consumption.
-- Dashboard totals (rounded): Jan 126,238; Feb 91,497; Mar 80,230;
-- Apr 78,770; May 79,059; Jun 65,405; Jul 81,674; Aug 68,559;
-- Sep 57,883; Oct 84,666; Nov 86,218; Dec 59,437 kWh.
SELECT
  EXTRACT(MONTH FROM date) AS month_number,
  ROUND(SUM(Usage_kWh), 2) AS total_usage_kwh
FROM `steel-industry-energy-analysis.steel_industry_data.steel_energy_clean`
GROUP BY month_number
ORDER BY month_number;

-- 06. ENERGY CONSUMPTION VS. LAGGING REACTIVE POWER
-- Validated averages:
-- Light_Load 8.63 kWh / 7.00 kVarh
-- Medium_Load 38.45 kWh / 14.41 kVarh
-- Maximum_Load 59.27 kWh / 26.19 kVarh
-- Higher-consumption load groups also show higher average reactive power.
-- Tableau trend-line analysis supplied the more detailed association analysis.
SELECT
  Load_Type,
  ROUND(AVG(Usage_kWh), 2) AS avg_usage_kwh,
  ROUND(AVG(Lagging_Current_Reactive_Power_kVarh), 2)
    AS avg_lagging_reactive_power_kvarh
FROM `steel-industry-energy-analysis.steel_industry_data.steel_energy_clean`
GROUP BY Load_Type
ORDER BY avg_usage_kwh;

-- 07. ENERGY CONSUMPTION VS. CO2 EMISSIONS
-- Validated averages:
-- Light_Load 8.63 kWh / 0.0026 tCO2
-- Medium_Load 38.45 kWh / 0.0167 tCO2
-- Maximum_Load 59.27 kWh / 0.0269 tCO2
-- This is descriptive evidence of association, not proof of causation.
SELECT
  Load_Type,
  ROUND(AVG(Usage_kWh), 2) AS avg_usage_kwh,
  ROUND(AVG(CO2_tCO2_), 4) AS avg_co2_tco2
FROM `steel-industry-energy-analysis.steel_industry_data.steel_energy_clean`
GROUP BY Load_Type
ORDER BY avg_usage_kwh;

-- ============================================================================
-- ANALYTICAL SUMMARY
-- 1. Overall average consumption: 27.39 kWh.
-- 2. Maximum_Load has the highest average consumption: 59.27 kWh.
-- 3. Peak average hourly consumption occurs at 9:00 AM: 58.55 kWh.
-- 4. Weekday average is ~2.9x the weekend average.
-- 5. January has the highest monthly total and September the lowest.
-- 6. Higher-consumption load conditions are associated with higher lagging
--    reactive power and higher recorded CO2 emissions.
--
-- These findings identify areas for further operational investigation; they
-- do not establish that any single factor causes the observed patterns.
-- ============================================================================

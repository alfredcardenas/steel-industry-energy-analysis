-- ============================================================
-- Project:      Steel Industry Energy Analysis
-- File:         01_data_quality_and_cleaning.sql
-- Phase:        PROCESS
-- Platform:     Google BigQuery (Standard SQL)
-- Source table: `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`
-- ============================================================
-- Purpose:
-- This script documents the PROCESS (data-quality validation) stage of the
-- Steel Industry Energy Analysis case study. It checks the raw dataset for
-- duplicates, missing values, categorical consistency, invalid numerical
-- ranges, statistical outliers, and time-series completeness.
--
-- All queries below are read-only. No records are modified, deleted, or
-- transformed, and no "cleaned" table is created, because the validation
-- did not surface evidence that any correction was required.
-- ============================================================


-- ============================================================
-- 1. DATASET OVERVIEW
-- ============================================================
-- Purpose:        Confirm the dataset contains the expected volume of data.
-- Method:         COUNT(*) on the raw table.
-- Result:         35,040 rows.
-- Interpretation: Matches one full year of 15-minute interval measurements
--                 (365 days x 96 observations/day = 35,040).

SELECT
  COUNT(*) AS total_rows
FROM
  `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`;


-- ============================================================
-- 2. DUPLICATE CHECK
-- ============================================================
-- Purpose:    Identify complete duplicate records, where a "complete
--             duplicate" means all 11 column values are identical.
-- Method:     GROUP BY every column, then filter for groups with more
--             than one row using HAVING COUNT(*) > 1.
-- Result:     0 complete duplicate records.
-- Decision:   No records were removed.

SELECT
  date,
  Usage_kWh,
  Lagging_Current_Reactive_Power_kVarh,
  Leading_Current_Reactive_Power_kVarh,
  CO2_tCO2_,
  Lagging_Current_Power_Factor,
  Leading_Current_Power_Factor,
  NSM,
  WeekStatus,
  Day_of_week,
  Load_Type,
  COUNT(*) AS record_count
FROM
  `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`
GROUP BY
  date,
  Usage_kWh,
  Lagging_Current_Reactive_Power_kVarh,
  Leading_Current_Reactive_Power_kVarh,
  CO2_tCO2_,
  Lagging_Current_Power_Factor,
  Leading_Current_Power_Factor,
  NSM,
  WeekStatus,
  Day_of_week,
  Load_Type
HAVING
  COUNT(*) > 1;


-- ============================================================
-- 3. MISSING VALUES
-- ============================================================
-- Purpose:    Confirm no column contains missing data that would need
--             imputation, replacement, or removal.
-- Method:     COUNTIF(column IS NULL) applied to each of the 11 columns.
-- Result:     All 11 columns returned 0 NULL values.
-- Decision:   No imputation, replacement, or row removal was required.

SELECT
  COUNTIF(date IS NULL)                                    AS null_date,
  COUNTIF(Usage_kWh IS NULL)                                AS null_usage_kwh,
  COUNTIF(Lagging_Current_Reactive_Power_kVarh IS NULL)     AS null_lagging_reactive_power,
  COUNTIF(Leading_Current_Reactive_Power_kVarh IS NULL)     AS null_leading_reactive_power,
  COUNTIF(CO2_tCO2_ IS NULL)                                AS null_co2,
  COUNTIF(Lagging_Current_Power_Factor IS NULL)             AS null_lagging_power_factor,
  COUNTIF(Leading_Current_Power_Factor IS NULL)             AS null_leading_power_factor,
  COUNTIF(NSM IS NULL)                                      AS null_nsm,
  COUNTIF(WeekStatus IS NULL)                               AS null_weekstatus,
  COUNTIF(Day_of_week IS NULL)                              AS null_day_of_week,
  COUNTIF(Load_Type IS NULL)                                AS null_load_type
FROM
  `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`;


-- ============================================================
-- 4. CATEGORICAL CONSISTENCY
-- ============================================================
-- Purpose:        Check the categorical fields for inconsistent spelling,
--                 capitalization, or duplicate category labels.
-- Method:         SELECT DISTINCT on each categorical column, ordered
--                 alphabetically for easy visual inspection.
-- Result:         WeekStatus (2 values), Day_of_week (7 values), and
--                 Load_Type (3 values) all returned exactly the expected
--                 categories.
-- Interpretation: No spelling, capitalization, or labeling inconsistencies
--                 were detected.
-- Decision:       No category standardization was required.

-- WeekStatus: expected values are "Weekday" and "Weekend"
SELECT DISTINCT
  WeekStatus
FROM
  `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`
ORDER BY
  WeekStatus;

-- Day_of_week: expected values are the 7 days of the week
SELECT DISTINCT
  Day_of_week
FROM
  `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`
ORDER BY
  Day_of_week;

-- Load_Type: expected values are Light_Load, Medium_Load, Maximum_Load
SELECT DISTINCT
  Load_Type
FROM
  `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`
ORDER BY
  Load_Type;


-- ============================================================
-- 5. NUMERICAL RANGE VALIDATION
-- ============================================================
-- Purpose:        Check MIN/MAX values for the main numerical variables to
--                 catch negative values or clearly invalid ranges.
-- Method:         MIN() and MAX() on each numerical column.
-- Result:         All values fall within physically plausible ranges.
--                 Both power factor columns are represented on a 0-100
--                 scale in this dataset (not the more common 0-1 scale).
-- Decision:       No observations were removed or corrected based solely
--                 on their minimum or maximum values.

SELECT
  MIN(Usage_kWh)                            AS min_usage_kwh,
  MAX(Usage_kWh)                            AS max_usage_kwh,
  MIN(Lagging_Current_Reactive_Power_kVarh) AS min_lagging_reactive_power,
  MAX(Lagging_Current_Reactive_Power_kVarh) AS max_lagging_reactive_power,
  MIN(Leading_Current_Reactive_Power_kVarh) AS min_leading_reactive_power,
  MAX(Leading_Current_Reactive_Power_kVarh) AS max_leading_reactive_power,
  MIN(CO2_tCO2_)                            AS min_co2,
  MAX(CO2_tCO2_)                            AS max_co2,
  MIN(Lagging_Current_Power_Factor)         AS min_lagging_power_factor,
  MAX(Lagging_Current_Power_Factor)         AS max_lagging_power_factor,
  MIN(Leading_Current_Power_Factor)         AS min_leading_power_factor,
  MAX(Leading_Current_Power_Factor)         AS max_leading_power_factor
FROM
  `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`;


-- ------------------------------------------------------------
-- 5.1 ZERO ENERGY CONSUMPTION INVESTIGATION
-- ------------------------------------------------------------
-- Purpose:        The minimum Usage_kWh value above was 0.00, so this
--                 value was investigated separately rather than assumed
--                 to be invalid.
-- Method:         Count how many records equal 0, then inspect the full
--                 row(s) with SELECT *.
-- Result:         1 record. It occurs at 2018-11-07 00:00:00 UTC, with
--                 NSM = 0 and every related electrical variable (reactive
--                 power, power factor, CO2) also equal to 0.
-- Interpretation: The observation is internally consistent across
--                 multiple variables and occurs exactly at midnight.
-- Decision:       The record was retained — there is insufficient
--                 evidence to classify it as a data-quality error.
--
-- Analytical principle: an unusual value should be investigated before
-- being automatically deleted.

-- Step 1: how many records have zero energy usage?
SELECT
  COUNT(*) AS zero_usage_count
FROM
  `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`
WHERE
  Usage_kWh = 0;

-- Step 2: inspect the record(s) in full
SELECT
  *
FROM
  `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`
WHERE
  Usage_kWh = 0;


-- ============================================================
-- 6. OUTLIER INVESTIGATION — USAGE_KWH
-- ============================================================
-- Purpose:        Identify statistical outliers in Usage_kWh using the
--                 Interquartile Range (IQR) method.
-- Method:         APPROX_QUANTILES() inside a CTE to get Q1/median/Q3,
--                 then the standard 1.5 x IQR rule for the lower/upper
--                 bounds.
-- Result:         Q1 = 3.20 kWh, Median = 4.57 kWh, Q3 = 50.76 kWh,
--                 IQR = 47.56 kWh, lower bound ≈ -68.14 kWh, upper bound
--                 ≈ 122.10 kWh. 368 observations (≈1.05% of the dataset)
--                 fall outside these bounds — almost entirely above the
--                 upper bound.
-- Interpretation: These high-usage observations cluster in hours
--                 compatible with active industrial operation
--                 (approximately 08:00-20:00). A statistical outlier is
--                 not automatically a data error.
-- Decision:       The potential outliers were retained — there is
--                 insufficient evidence that they represent erroneous
--                 observations.
--
-- Note: APPROX_QUANTILES() is an approximate algorithm rather than an
-- exact quantile calculation. On a right-skewed distribution like
-- Usage_kWh, an exact-quantile method can return a slightly different
-- outlier count than the 368 reported here. This does not change the
-- underlying conclusion — a small minority of high-usage observations,
-- concentrated in active operating hours — but the exact count is
-- method-dependent.

-- Step 1: calculate Q1, median, Q3, IQR, and the outlier bounds
WITH quartiles AS (
  SELECT
    APPROX_QUANTILES(Usage_kWh, 4)[OFFSET(1)] AS q1,
    APPROX_QUANTILES(Usage_kWh, 4)[OFFSET(2)] AS median,
    APPROX_QUANTILES(Usage_kWh, 4)[OFFSET(3)] AS q3
  FROM
    `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`
)
SELECT
  q1,
  median,
  q3,
  (q3 - q1)                AS iqr,
  q1 - 1.5 * (q3 - q1)      AS lower_bound,
  q3 + 1.5 * (q3 - q1)      AS upper_bound
FROM
  quartiles;

-- Step 2: count how many observations fall outside those bounds
-- (the bounds are recalculated here rather than hard-coded, so the
-- query stays correct if it is re-run against updated data)
WITH quartiles AS (
  SELECT
    APPROX_QUANTILES(Usage_kWh, 4)[OFFSET(1)] AS q1,
    APPROX_QUANTILES(Usage_kWh, 4)[OFFSET(3)] AS q3
  FROM
    `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`
),
bounds AS (
  SELECT
    q1 - 1.5 * (q3 - q1) AS lower_bound,
    q3 + 1.5 * (q3 - q1) AS upper_bound
  FROM
    quartiles
)
SELECT
  COUNT(*) AS potential_outliers,
  ROUND(
    COUNT(*) * 100 / (
      SELECT COUNT(*)
      FROM `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`
    ),
    2
  ) AS pct_of_dataset
FROM
  `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw` AS raw
CROSS JOIN
  bounds
WHERE
  raw.Usage_kWh < bounds.lower_bound
  OR raw.Usage_kWh > bounds.upper_bound;


-- ============================================================
-- 7. NSM AND TIMESTAMP VALIDATION
-- ============================================================
-- Purpose:        Confirm that NSM (Number of Seconds from Midnight) is
--                 internally valid and consistent with the `date`
--                 timestamp.
-- Method:         (a) MIN/MAX range check, (b) MOD(NSM, 900) to confirm
--                 every value aligns to a 15-minute boundary
--                 (15 min x 60 sec = 900 sec), and (c) a comparison of
--                 NSM against the time portion of `date`.
-- Result:         NSM ranges from 0 (00:00) to 85,500 (23:45); 0 records
--                 fail the 15-minute alignment check; 0 records are
--                 inconsistent between NSM and the `date` timestamp.
-- Decision:       No time-related corrections were required.

-- Step 1: NSM range check
SELECT
  MIN(NSM) AS min_nsm,
  MAX(NSM) AS max_nsm
FROM
  `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`;

-- Step 2: confirm every NSM value falls on a 15-minute (900-second) boundary
SELECT
  COUNT(*) AS invalid_nsm_intervals
FROM
  `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`
WHERE
  MOD(NSM, 900) != 0;

-- Step 3: confirm NSM matches the time portion of the `date` timestamp
SELECT
  COUNT(*) AS nsm_timestamp_mismatches
FROM
  `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`
WHERE
  NSM != (
    EXTRACT(HOUR FROM date) * 3600
    + EXTRACT(MINUTE FROM date) * 60
    + EXTRACT(SECOND FROM date)
  );


-- ============================================================
-- 8. TIME-SERIES COMPLETENESS
-- ============================================================
-- Purpose:        Confirm the dataset represents a complete, uninterrupted
--                 year of 15-minute readings (24h x 4 readings/hour =
--                 96 readings/day).
-- Method:         GROUP BY DATE(date) with HAVING COUNT(*) != 96, plus a
--                 MIN/MAX/COUNT(DISTINCT ...) check on the date range.
-- Result:         No day returned a record count other than 96. The data
--                 spans 2018-01-01 00:00:00 UTC to 2018-12-31 23:45:00
--                 UTC across 365 distinct days (365 x 96 = 35,040,
--                 matching the total row count from Section 1).
-- Decision:       The dataset represents a complete year of measurements.

-- Step 1: flag any day that does not contain exactly 96 records
SELECT
  DATE(date) AS record_date,
  COUNT(*)   AS records_per_day
FROM
  `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`
GROUP BY
  record_date
HAVING
  COUNT(*) != 96
ORDER BY
  record_date;

-- Step 2: overall date range and distinct day count
SELECT
  MIN(date)                    AS first_record,
  MAX(date)                    AS last_record,
  COUNT(DISTINCT DATE(date))   AS distinct_days
FROM
  `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`;

-- Step 3: confirm that each day contains 96 unique 15-minute slots
-- Purpose:        Verify slot-level uniqueness within each day.
-- Method:         COUNT(DISTINCT NSM) per date and flag any day that does
--                 not contain exactly 96 unique NSM values.
-- Result:         No rows returned.
-- Interpretation: Every day contains exactly 96 distinct NSM values,
--                 confirming that all expected 15-minute time slots are
--                 unique within each day.
-- Decision:       No missing or duplicated daily time slots were detected.
SELECT
  DATE(date) AS record_date,
  COUNT(DISTINCT NSM) AS distinct_nsm_values
FROM
  `steel-industry-energy-analysis.steel_industry_data.steel_energy_raw`
GROUP BY
  record_date
HAVING
  COUNT(DISTINCT NSM) != 96
ORDER BY
  record_date;


-- ============================================================
-- 9. FINAL DATA QUALITY CONCLUSION
-- ============================================================
-- Verified PROCESS findings:
--   - 35,040 observations across 365 days (96 observations/day)
--   - Full 2018 temporal coverage (2018-01-01 to 2018-12-31)
--   - 0 complete duplicate records
--   - 0 NULL values across all 11 columns
--   - Categorical variables (WeekStatus, Day_of_week, Load_Type) are
--     consistent, with no spelling or labeling issues
--   - No obviously invalid numerical ranges in any numeric column
--   - 1 Usage_kWh = 0 observation was investigated and retained
--   - 368 potential Usage_kWh statistical outliers (~1.05% of the
--     dataset) were identified using the IQR method, investigated, and
--     retained
--   - NSM values align with 15-minute increments (0 invalid intervals)
--   - 0 inconsistencies between NSM and the `date` timestamp
--   - Every day contains 96 distinct NSM values, confirming complete
--     and unique 15-minute time slots
--
-- Final decision:
-- No records required removal or correction before analysis. The
-- dataset was considered suitable to proceed to the ANALYZE phase.

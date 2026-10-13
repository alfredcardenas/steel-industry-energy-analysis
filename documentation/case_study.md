# Steel Industry Energy Consumption Analysis — Case Study

This case study documents the reasoning behind the Steel Industry Energy Consumption project: why each phase was approached the way it was, what the SQL and dashboard work actually show, and where the boundaries of that evidence are. The [README](../README.md) covers the summary; this document covers the "why."

## 1. Introduction

The dataset behind this project is a full year of 15-minute interval electricity measurements from a steel manufacturing facility, sourced from the UCI Machine Learning Repository. At that resolution, the raw data is too granular to interpret directly — 35,040 rows of near-continuous readings don't tell a person much on their own. The purpose of this project was to turn that raw interval data into a small set of well-supported, well-scoped findings about *when* consumption is highest and *what recorded conditions* it's associated with, using the analytical framework taught in the Google Data Analytics program: Ask, Prepare, Process, Analyze, Share, Act.

A recurring theme throughout this project is the difference between an observed pattern and an explained one. The dataset can show that consumption is higher on weekdays, or that it rises alongside reactive power — but it cannot say *why*, because it contains no information about production volume, scheduling, or equipment. Keeping that distinction explicit, rather than filling the gap with a plausible-sounding guess, was treated as part of the analytical work itself, not an afterthought.

## 2. Ask

The guiding question for this project was: what temporal and operational patterns exist in this facility's electricity consumption, and how does that consumption relate to the other electrical variables recorded alongside it (load type, reactive power, power factor, CO2)?

This framing was chosen deliberately over a narrower question like "how much electricity does the facility use," because the dataset's real value is in its structure — timestamps, categorical load classifications, and multiple correlated electrical measurements — not just the raw usage figures. A single average consumption number is not very actionable; knowing *when* and *under what conditions* consumption peaks is.

The scope was also bounded early. Because the dataset has no production, cost, or maintenance data, questions like "is this facility running efficiently" or "how much money could be saved" were explicitly excluded — they would require data this project doesn't have.

## 3. Prepare

Before writing any analytical SQL, the dataset was reviewed in BigQuery for basic fitness for purpose: schema, data types, timestamp coverage, the categorical variables, and — just as importantly — what the dataset *didn't* contain. That review surfaced the same constraint that shaped the Ask phase: no electricity prices, no production output, no equipment-level breakdown, no maintenance records, no process detail, no weather data. Establishing those gaps before analysis, rather than discovering them while writing conclusions, is what made it possible to keep the later findings appropriately scoped instead of overreaching.

## 4. Process

The Process phase (`sql/01_data_quality_and_cleaning.sql`) is a validation script, not a cleaning script in the sense of correcting bad data — the checks below found nothing that needed correcting, so nothing was changed. That result was not assumed going in.

**Duplicates and nulls.** A `GROUP BY` across all 11 columns with `HAVING COUNT(*) > 1` found zero complete duplicate rows, and `COUNTIF(... IS NULL)` across every column found zero missing values. Both checks needed to run before anything else, since duplicates or nulls would have distorted every average and correlation calculated later.

**Categorical consistency.** `SELECT DISTINCT` on `WeekStatus`, `Day_of_week`, and `Load_Type` confirmed exactly the expected category labels with no inconsistent spelling or casing — a common source of silently wrong `GROUP BY` results if left unchecked.

**Range validation and the zero-usage record.** `MIN()`/`MAX()` on each numeric column turned up one value worth a closer look: a minimum `Usage_kWh` of exactly 0. Rather than treat that as an error by default, the record was isolated and inspected in full. It occurred at exactly midnight, and every other electrical variable in that same row (reactive power, power factor, CO2) was also 0 — internally consistent with a facility that was briefly idle, not a broken sensor reading. It was kept.

**Outlier investigation.** The same reasoning applied at scale, using the interquartile range (IQR) method: Q1, median, and Q3 were computed with `APPROX_QUANTILES()`, and the standard 1.5×IQR rule flagged about 368 observations (≈1.05% of the dataset) as statistical outliers, almost entirely on the high side. Before deciding what to do with them, they were checked against the hours they occurred in — and they cluster during hours consistent with active industrial operation, not scattered randomly across the day. In an industrial energy dataset, a "statistical outlier" is often just a real high-demand operating period, so the decision was to retain them rather than delete them. Deleting statistically unusual but operationally plausible readings would have quietly removed exactly the high-consumption events this project cares most about.

*A methodological note:* `APPROX_QUANTILES()` is, as the name states, approximate. On a right-skewed distribution like `Usage_kWh`, an exact quantile calculation can return a slightly different outlier count than 368. That doesn't change the conclusion — a small minority of high-usage readings, concentrated in operating hours — but it's worth flagging as a property of the method rather than treating the count as exact to the observation.

**Time integrity.** `NSM` (seconds since midnight) was checked for range, for alignment to 900-second (15-minute) boundaries, and for consistency against the `date` timestamp itself — all passed with zero discrepancies. A day-by-day record count confirmed all 365 days contain exactly 96 readings each (35,040 total), and a further check confirmed 96 *distinct* `NSM` values per day, ruling out both missing and duplicated time slots.

The conclusion of Process was that the dataset needed no corrections. That's a legitimate, useful outcome of a validation phase — the value was in confirming it systematically rather than assuming it.

## 5. Analyze

The exploratory analysis (`sql/02_exploratory_analysis.sql`) runs seven queries against the validated data, each built around a specific question rather than an open-ended exploration.

**Overall average (27.39 kWh) and by load type.** A plain `AVG(Usage_kWh)` establishes the baseline. Grouping the same average by `Load_Type` (Light_Load 8.63, Medium_Load 38.45, Maximum_Load 59.27 kWh) shows a large, monotonic gap between categories — showing substantial differences in average consumption across load categories, and motivating the later reactive-power and CO2 comparisons. These descriptive averages do not establish causality or quantify explained variance.

*Insight:* consumption rises consistently from Light to Medium to Maximum Load.
*Interpretation:* the Load_Type label appears to track real differences in operating intensity.
*What this doesn't show:* whether Maximum_Load represents necessary production activity or an inefficient state — the dataset has no output data to distinguish the two, so no efficiency judgment is made here.

**Weekday vs. weekend.** Grouping by `WeekStatus` gives 33.62 kWh (weekday) vs. 11.73 kWh (weekend). The ratio (33.62 / 11.73 ≈ 2.87) is reported as "the weekday average is approximately 2.9 times the weekend average" rather than "2.9x higher" — those two phrasings describe different quantities, and the more precise one was used deliberately. It's also worth noting explicitly that this comparison is Weekday vs. Weekend as a whole, not a day-by-day breakdown — the data doesn't support singling out, say, Monday specifically as a driver.

**Hourly pattern.** `EXTRACT(HOUR FROM date)` converts each timestamp into an hour-of-day bucket before averaging. The resulting profile — low overnight, a sharp rise around 8–9 AM, sustained high demand through the morning, a dip near midday, a second elevated period in the afternoon, and a decline into the evening — is a strong enough shape that it's very likely tied to a facility operating schedule. But the dataset doesn't record what that schedule is, so no specific shift pattern or process is named; the pattern is described, not explained.

**Monthly totals.** `SUM(Usage_kWh)` grouped by `EXTRACT(MONTH FROM date)` was used here instead of `AVG()`, because the business-relevant question for a full month is total energy drawn, not the average of individual 15-minute readings. January is the highest month (126,238 kWh) and September the lowest (57,883 kWh). No explanation is offered for that gap — production schedules, seasonal effects, and maintenance windows are all plausible, untestable candidates given what's in the dataset.

**Reactive power and CO2.** Both comparisons follow the same structure: average `Usage_kWh` alongside average `Lagging_Current_Reactive_Power_kVarh` (query 06) or average `CO2_tCO2_` (query 07), grouped by `Load_Type`. Both variables rise in step with `Usage_kWh` across the three load categories. The more detailed relationship — strength and shape of the association — was assessed with Tableau's trend-line feature rather than in SQL: fitting a linear trend to Usage vs. reactive power within each load type produced R² values in the 0.70–0.89 range, with trend-line p-values below 0.0001, describing a strong positive relationship. That wording — "strong positive relationship / association" — is used intentionally instead of any causal phrasing. A high R² describes how tightly two variables move together, not which one (if either) drives the other. For CO2, only the directional pattern (higher-consumption load groups show higher average recorded CO2) is reported, since a precise R² for that relationship wasn't independently verified here.

## 6. Share

The Tableau dashboard was designed around a simple idea: lead with the numbers a reader needs first, then let them drill into the supporting detail. The three KPI cards at the top (overall average, peak average hour, highest-consuming load type) answer the most immediate questions in under five seconds. The six charts beneath them map directly onto the seven Analyze queries: a monthly bar chart for the total-consumption trend, a load-type bar chart for the categorical comparison, an hourly line chart for the daily pattern, a weekday-vs-weekend comparison, and two scatter plots with trend lines for the reactive-power and CO2 relationships. A short Key Insights panel calls out the three findings judged most relevant to an energy-management audience — the 9:00 AM peak, the weekday/weekend gap, and the reactive-power relationship — rather than repeating every number already visible in the charts.

## 7. Act

Each recommendation below follows the same structure used throughout this project: what the data shows, what that might mean operationally, and what should be investigated next — kept as three separate, clearly labeled steps rather than collapsed into a single claim.

**1. Peak demand.**
*Insight:* average consumption peaks at 9:00 AM (58.55 kWh).
*Interpretation:* this is very likely tied to a specific point in the facility's daily operating cycle.
*Recommendation:* prioritize energy-efficiency initiatives around the 9:00 AM window, and investigate which specific operational activities are driving the elevated demand — this dataset identifies *when*, not *what*.

**2. Maximum Load.**
*Insight:* Maximum_Load periods average nearly 7× the consumption of Light_Load periods.
*Interpretation:* Maximum_Load periods are where the largest share of total electricity use is concentrated.
*Recommendation:* investigate the operating conditions during Maximum_Load periods for efficiency opportunities, without assuming those periods represent waste — higher consumption may simply reflect legitimate higher-output operation.

**3. Reactive power.**
*Insight:* reactive power rises alongside consumption, with a strong relationship (R² 0.70–0.89) across all three load types.
*Interpretation:* reactive power is a variable worth watching alongside consumption, though this data cannot establish that it drives higher usage.
*Recommendation:* evaluate reactive power and power factor specifically during high-consumption periods to determine whether power-factor correction would be technically and economically justified. This project does not recommend a specific equipment purchase — that decision needs a technical and economic analysis this dataset can't provide.

**4. Weekday operations.**
*Insight:* weekday consumption is roughly 2.9× the weekend average.
*Interpretation:* whatever drives the bulk of this facility's energy use is concentrated in weekday operations.
*Recommendation:* prioritize efficiency efforts during weekdays and monitor operational parameters during those periods to identify specific drivers — without attributing the effect to any single weekday.

**5. CO2 monitoring.**
*Insight:* higher-consumption load categories show higher average recorded CO2.
*Interpretation:* CO2 tracks consumption closely enough to be a useful secondary indicator, though the two should still be treated as associated, not causally linked, without further documentation of how the CO2 field was calculated.
*Recommendation:* monitor CO2 during high-consumption periods, and, if production data becomes available in the future, calculate emissions-intensity KPIs such as CO2/kWh or CO2/ton of steel to give the CO2 figures operational meaning beyond raw totals.

## 8. Limitations

The dataset provides electrical measurements at high temporal resolution, but no operational context to explain *why* those measurements move the way they do. Specifically, without production-output data, it is not possible to determine whether periods of higher consumption reflect more output, lower efficiency, different equipment in use, or a different production schedule — all four are equally consistent with the data available. The relationships between consumption, reactive power, and CO2 are described throughout as associations for the same reason: a strong statistical relationship does not identify which variable, if any, is driving the other. Finally, because this is a single facility over a single year, none of these findings are generalized to steel manufacturing more broadly.

## 9. Conclusion

This project took a large, granular energy dataset and reduced it to a focused set of findings about when and under what conditions a steel facility's electricity consumption is highest — validated through systematic SQL checks in BigQuery, and communicated through a Tableau dashboard built around the same findings. The analytical discipline applied throughout — distinguishing insight from interpretation from recommendation, and association from causation — is intended to make the conclusions defensible on their own terms: useful starting points for further operational investigation, not final answers the data was never positioned to give.

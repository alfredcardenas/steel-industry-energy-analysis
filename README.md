# Steel Industry Energy Consumption Analysis

An end-to-end data analysis case study examining one year of 15-minute interval electricity consumption from a steel manufacturing facility. The project covers data validation, SQL-based exploratory analysis in Google BigQuery, and dashboard development in Tableau, following the Ask–Prepare–Process–Analyze–Share–Act framework.

## Business Problem

Steel manufacturing is an energy-intensive process, and electricity use can vary significantly depending on when and how a facility is operating. This project analyzes a full year of interval-level energy data to identify when consumption is highest, how it differs across operating conditions, and how it relates to other recorded electrical variables — with the goal of surfacing patterns that would be worth investigating further for energy-management purposes.

The analysis distinguishes between what the data demonstrates, what it suggests, and what would require additional operational data (such as production output) to determine with confidence.

## Dataset

| | |
|---|---|
| **Name** | Steel Industry Energy Consumption |
| **Source** | [UCI Machine Learning Repository](https://archive.ics.uci.edu/dataset/851/steel+industry+energy+consumption) |
| **DOI** | 10.24432/C52G8C |
| **Authors** | Sathishkumar V E, Changsun Shin, Yongyun Cho |
| **License** | CC BY 4.0 |
| **Observations** | 35,040 (15-minute intervals, full year 2018) |

Key variables: `date`, `Usage_kWh`, `Lagging_Current_Reactive_Power_kVarh`, `Leading_Current_Reactive_Power_kVarh`, `CO2_tCO2_`, `Lagging_Current_Power_Factor`, `Leading_Current_Power_Factor`, `NSM`, `WeekStatus`, `Day_of_week`, `Load_Type`.

See [`data/README.md`](data/README.md) for full attribution and details.

## Tools

- **Google BigQuery / SQL** — data validation, data-quality checks, and exploratory analysis
- **Tableau** — KPI cards, trend and relationship visualizations, and dashboard development
- **GitHub** — project documentation and portfolio presentation

## Analysis Process

| Phase | Summary |
|---|---|
| **Ask** | Defined the analytical objective: identify temporal and operational patterns in energy consumption and examine their relationship to load type, reactive power, power factor, and CO2. |
| **Prepare** | Reviewed the dataset's structure, types, and suitability in BigQuery; confirmed it does not include production, cost, or weather data. |
| **Process** | Validated the raw data in SQL — checked for duplicates, nulls, categorical consistency, numerical ranges, and outliers. |
| **Analyze** | Ran exploratory SQL to quantify consumption by time period and load type, and its relationship with reactive power and CO2. |
| **Share** | Built a Tableau dashboard presenting the validated findings as KPI cards and charts. |
| **Act** | Translated findings into evidence-based recommendations for further operational investigation. |

## Data Cleaning

Data-quality validation (`sql/01_data_quality_and_cleaning.sql`) checked the full 35,040-row dataset and found:

- **0** complete duplicate records
- **0** NULL values across all 11 columns
- Categorical fields (`WeekStatus`, `Day_of_week`, `Load_Type`) consistent, with no spelling or labeling issues
- All numerical ranges plausible; no negative or out-of-range values
- **1** zero-consumption observation, investigated and retained (internally consistent — every related electrical variable was also 0, at exactly midnight)
- **368** potential statistical outliers in `Usage_kWh` (≈1.05% of the dataset), identified using an IQR-based check and retained — they cluster in hours consistent with active industrial operation and are treated as plausible high-consumption conditions rather than errors

The cleaning approach was intentionally conservative: no rows were removed or altered, since the validation found no evidence that any correction was needed.

## Key Findings

| Metric | Result |
|---|---|
| Overall average consumption | 27.39 kWh |
| Highest average consumption by load | Maximum_Load — 59.27 kWh |
| Peak average consumption hour | 9:00 AM — 58.55 kWh |
| Weekday average | 33.62 kWh |
| Weekend average | 11.73 kWh |
| Weekday vs. weekend | Weekday average is approximately 2.9× the weekend average |
| Highest monthly total | January — 126,238 kWh |
| Lowest monthly total | September — 57,883 kWh |
| Usage vs. reactive power | Strong positive relationship (R² ≈ 0.70–0.89 across load types) |
| Usage vs. CO2 | Higher-consumption load groups show higher average recorded CO2 |

Consumption is consistently higher on weekdays, peaks during two daytime windows, and rises together with both load classification and lagging reactive power. These are descriptive associations from the available data, not evidence of cause and effect.


### Web dashboard

A redesigned two-view version of the dashboard is published as a web page (HTML, CSS and JavaScript) with GitHub Pages:
**[View the web dashboard →](https://alfredcardenas.github.io/steel-industry-energy-analysis/)**

- **Executive Overview:** KPIs, hourly profile, load type, monthly totals, weekday vs. weekend.
- **Detailed Analysis:** correlation (r) and R² for reactive power, CO2 and power factor, plus share of intervals vs. share of energy by load type.

![Web dashboard: Executive Overview](docs/screenshots/dashboard_executive_overview.png)

Every value shown on the web dashboard is checked against the 35,040-row data export embedded in the Tableau workbook by [`scripts/verify_metrics.py`](scripts/verify_metrics.py). See [`docs/README.md`](docs/README.md) for details.

## Business Recommendations

1. **Peak demand.** Prioritize energy-efficiency initiatives around the 9:00 AM peak period, and investigate which operational activities are driving the elevated demand.
2. **Maximum Load.** Investigate the operational conditions associated with Maximum_Load periods to identify opportunities for improving energy efficiency without compromising production requirements.
3. **Reactive power.** Evaluate reactive power and power factor during high-consumption periods to determine whether power-factor correction measures could improve electrical efficiency and reduce potential reactive-power-related costs.
4. **Weekday operations.** Prioritize energy-efficiency efforts during weekdays, when average consumption is approximately 2.9× the weekend average, and monitor operational parameters during these periods to identify specific drivers of higher demand.
5. **CO2 monitoring.** Prioritize monitoring of CO2 emissions during high-energy-consumption periods, and integrate production data in future analyses to evaluate emissions intensity (e.g., CO2/kWh, and CO2/ton of steel if production data becomes available).

These are directions for further investigation, not final operational decisions — see Limitations below.

## Limitations

This dataset contains energy and electrical measurements but no production-output, cost, maintenance, or weather data. As a result:

- It is not possible to determine whether higher energy consumption reflects greater production, lower efficiency, different equipment usage, different scheduling, or another operational factor.
- The relationships observed between energy consumption, reactive power, and CO2 are associations, not causal relationships.
- Recommendations are framed as areas for operational investigation and monitoring, not as proven cost savings or guaranteed efficiency gains.

## Skills Demonstrated

SQL · Google BigQuery · Data Cleaning · Data Validation · Exploratory Data Analysis · Data Visualization · Tableau · Analytical Reasoning · Business Recommendations · GitHub Documentation

## Repository Structure

```
steel-industry-energy-analysis/
│
├── README.md
│
├── data/
│   └── README.md
│
├── sql/
│   ├── 01_data_quality_and_cleaning.sql
│   ├── 02_exploratory_analysis.sql
│   └── 03_dashboard_supporting_metrics.sql
│
├── docs/                      ← web dashboard (GitHub Pages)
│   ├── index.html
│   ├── styles.css
│   ├── script.js
│   ├── data/data.js
│   ├── screenshots/
│   └── README.md
│
├── scripts/
│   └── verify_metrics.py
│
├── tableau/
│   └── Steel_Industry_Energy_Analysis.twbx
│
├── images/
│   └── steel_industry_energy_dashboard.png
│
└── documentation/
    ├── case_study.md
    └── dashboard_audit.md
```

## Data Source / Attribution

Sathishkumar V E, Changsun Shin, and Yongyun Cho. **Steel Industry Energy Consumption** [Dataset]. UCI Machine Learning Repository, 2018. https://doi.org/10.24432/C52G8C. Licensed under CC BY 4.0.

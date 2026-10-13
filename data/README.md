# Data

## Dataset

**Steel Industry Energy Consumption** — 35,040 observations of 15-minute interval electricity measurements from a steel manufacturing facility, covering the full 2018 calendar year (11 columns: `date`, `Usage_kWh`, `Lagging_Current_Reactive_Power_kVarh`, `Leading_Current_Reactive_Power_kVarh`, `CO2_tCO2_`, `Lagging_Current_Power_Factor`, `Leading_Current_Power_Factor`, `NSM`, `WeekStatus`, `Day_of_week`, `Load_Type`).

## Source and Attribution

- **Repository:** [UCI Machine Learning Repository](https://archive.ics.uci.edu/dataset/851/steel+industry+energy+consumption)
- **DOI:** [10.24432/C52G8C](https://doi.org/10.24432/C52G8C)
- **Authors:** Sathishkumar V E, Changsun Shin, Yongyun Cho
- **License:** CC BY 4.0

Citation:

> Sathishkumar V E, Changsun Shin, and Yongyun Cho. Steel Industry Energy Consumption [Dataset]. UCI Machine Learning Repository, 2018. https://doi.org/10.24432/C52G8C.

## Why the raw file isn't included here

The raw dataset (35,040 rows) is not duplicated in this repository. It's publicly available directly from the UCI Machine Learning Repository at the link above, which is the authoritative, versioned source — linking to it keeps this repository lightweight and avoids maintaining a static copy that could drift out of sync with the original. For this project, the data was loaded into the Google BigQuery dataset `steel-industry-energy-analysis.steel_industry_data`, with the tables `steel_energy_raw` and `steel_energy_clean` used for validation and analysis; the SQL in [`../sql/`](../sql/) references these tables and can be run against a fresh import of the same source data.

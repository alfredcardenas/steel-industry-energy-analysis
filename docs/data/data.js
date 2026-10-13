/*
 * Steel Industry Energy Consumption — validated summary values
 * ------------------------------------------------------------
 * Aggregates of the full dataset: 35,040 fifteen-minute intervals, calendar year 2018.
 *
 * Provenance
 *   - KPIs, hourly, monthly, load-type and weekday/weekend values:
 *     sql/02_exploratory_analysis.sql (BigQuery)
 *   - Record/energy shares and correlations: ANALYZE-phase queries, reproduced in
 *     sql/03_dashboard_supporting_metrics.sql
 *   - Every value was re-checked with scripts/verify_metrics.py against the data
 *     export embedded in tableau/Steel_Industry_Energy_Analysis.twbx (35,040 rows).
 *
 * These are STATIC aggregates. The dashboard has no filters; the only value
 * derived in the browser is the weekday/weekend ratio.
 *
 * Units
 *   - "avg" values  = average Usage_kWh per 15-minute interval
 *   - "total" values = SUM(Usage_kWh) over the period
 *
 * Source: Sathishkumar V E, Changsun Shin, Yongyun Cho. Steel Industry Energy
 * Consumption [Dataset]. UCI Machine Learning Repository, 2018.
 * https://doi.org/10.24432/C52G8C (CC BY 4.0)
 *
 * Kept as a .js file (not .json) so the dashboard also works when index.html
 * is opened directly from disk, where browsers block fetch() of local files.
 */
window.STEEL_DATA = {
  meta: {
    observations: 35040,
    year: 2018,
    totalKwh: 959636.71
  },

  kpis: {
    avgKwh: 27.39,          // AVG(Usage_kWh), all intervals
    peakHourAvgKwh: 58.55,  // highest hourly average (09:00)
    peakHour: 9,
    weekdayAvgKwh: 33.62,
    weekendAvgKwh: 11.73,   // ratio 33.62 / 11.73 = 2.87 ≈ 2.9×
    weekdayRecords: 25056,
    weekendRecords: 9984
  },

  // AVG(Usage_kWh) grouped by hour of day (DIV(NSM, 3600)), hours 0–23
  hourlyAvgKwh: [
    7.87, 6.07, 4.43, 4.36, 4.31, 4.25, 4.22, 4.50,
    37.70, 58.55, 55.87, 57.10, 18.46, 39.02, 56.16, 55.64,
    55.80, 43.83, 33.02, 38.21, 37.48, 13.78, 8.66, 8.00
  ],

  // SUM(Usage_kWh) grouped by EXTRACT(MONTH FROM date) — TOTALS, not averages
  monthlyTotalKwh: [
    { month: "Jan", total: 126238.29 },
    { month: "Feb", total: 91497.34 },
    { month: "Mar", total: 80230.41 },
    { month: "Apr", total: 78769.80 },
    { month: "May", total: 79059.28 },
    { month: "Jun", total: 65404.64 },
    { month: "Jul", total: 81674.41 },
    { month: "Aug", total: 68559.43 },
    { month: "Sep", total: 57883.07 },
    { month: "Oct", total: 84665.65 },
    { month: "Nov", total: 86217.61 },
    { month: "Dec", total: 59436.78 }
  ],

  // Grouped by Load_Type
  loadTypes: [
    {
      key: "Light_Load", label: "Light",
      records: 18072, pctRecords: 51.58,
      avgKwh: 8.63, totalKwh: 155892.81, pctEnergy: 16.24,
      avgLaggingKvarh: 7.00, avgCo2: 0.0026, totalCo2: 46.15, avgLaggingPf: 69.68
    },
    {
      key: "Medium_Load", label: "Medium",
      records: 9696, pctRecords: 27.67,
      avgKwh: 38.45, totalKwh: 372766.54, pctEnergy: 38.84,
      avgLaggingKvarh: 14.41, avgCo2: 0.0167, totalCo2: 162.05, avgLaggingPf: 93.06
    },
    {
      key: "Maximum_Load", label: "Maximum",
      records: 7272, pctRecords: 20.75,
      avgKwh: 59.27, totalKwh: 430977.36, pctEnergy: 44.91,
      avgLaggingKvarh: 26.19, avgCo2: 0.0269, totalCo2: 195.61, avgLaggingPf: 91.01
    }
  ],

  // Pearson r from CORR() over all 35,040 intervals (NOT R² — see rSquared below)
  correlations: {
    usageVsLaggingKvarh: 0.8961,
    usageVsCo2: 0.9882,
    usageVsLaggingPf: 0.3860
  },

  // R² = r² computed from the UNROUNDED r (squaring the rounded r above would
  // give 0.977 instead of 0.976 for CO2). Rounded to 3 decimals for display.
  rSquared: {
    usageVsLaggingKvarh: 0.803,
    usageVsCo2: 0.976,
    usageVsLaggingPf: 0.149
  }
};

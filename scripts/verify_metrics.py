"""
Verify every number shown in the web dashboard against the raw data.

Usage:
    python scripts/verify_metrics.py <path-to-csv>

The CSV is the 35,040-row BigQuery export that Tableau stores inside
tableau/Steel_Industry_Energy_Analysis.twbx (a .twbx is a zip file:
unzip it and use the CSV in Data/Downloads/). The same check works on any
export of the steel_energy_clean table with the original column names.

The script reads the values in docs/data/data.js, recomputes each one from
the CSV with pandas, and prints PASS/FAIL per metric. Exit code 1 if any fail.
Requires: pandas, numpy.
"""
import json
import re
import sys
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
DATA_JS = ROOT / "docs" / "data" / "data.js"


def load_dashboard_values(path):
    text = path.read_text(encoding="utf-8")
    body = text[text.index("window.STEEL_DATA =") + len("window.STEEL_DATA ="):]
    body = body[: body.rindex("};") + 1]
    body = re.sub(r"//[^\n]*", "", body)                       # strip comments
    body = re.sub(r"([{,]\s*)([A-Za-z_]\w*)\s*:", r'\1"\2":', body)  # quote keys
    body = re.sub(r",(\s*[}\]])", r"\1", body)                 # trailing commas
    return json.loads(body)


def main(csv_path):
    D = load_dashboard_values(DATA_JS)
    df = pd.read_csv(csv_path)
    u = df["Usage_kWh"]
    results = []

    def check(name, shown, actual, tol):
        ok = abs(shown - actual) <= tol
        results.append(ok)
        print(f"{'PASS' if ok else 'FAIL'}  {name:<46} dashboard={shown:<12} recomputed={actual:.6g}")

    check("observations", D["meta"]["observations"], len(df), 0)
    check("total kWh (SUM)", D["meta"]["totalKwh"], u.sum(), 0.005)

    k = D["kpis"]
    week = df.groupby("WeekStatus")["Usage_kWh"].agg(["mean", "size"])
    hourly = df.groupby(df["NSM"] // 3600)["Usage_kWh"].mean()
    check("KPI avg kWh per interval (AVG)", k["avgKwh"], u.mean(), 0.005)
    check("KPI peak hourly avg (AVG by hour, max)", k["peakHourAvgKwh"], hourly.max(), 0.005)
    check("KPI peak hour", k["peakHour"], hourly.idxmax(), 0)
    check("weekday avg (AVG)", k["weekdayAvgKwh"], week.loc["Weekday", "mean"], 0.005)
    check("weekend avg (AVG)", k["weekendAvgKwh"], week.loc["Weekend", "mean"], 0.005)
    check("weekday records", k["weekdayRecords"], week.loc["Weekday", "size"], 0)
    check("weekend records", k["weekendRecords"], week.loc["Weekend", "size"], 0)
    check("weekday/weekend ratio (rounded 2.9)",
          round(k["weekdayAvgKwh"] / k["weekendAvgKwh"], 1),
          week.loc["Weekday", "mean"] / week.loc["Weekend", "mean"], 0.05)

    for h, v in enumerate(D["hourlyAvgKwh"]):
        check(f"hourly avg {h:02d}:00 (AVG)", v, hourly.loc[h], 0.005)

    month = df.groupby(pd.to_datetime(df["date"].str.replace(" UTC", "")).dt.month)["Usage_kWh"].sum()
    for i, m in enumerate(D["monthlyTotalKwh"], start=1):
        check(f"monthly total {m['month']} (SUM)", m["total"], month.loc[i], 0.005)

    g = df.groupby("Load_Type")
    for lt in D["loadTypes"]:
        s = g.get_group(lt["key"])
        check(f"{lt['key']} records", lt["records"], len(s), 0)
        check(f"{lt['key']} % of records", lt["pctRecords"], 100 * len(s) / len(df), 0.005)
        check(f"{lt['key']} avg kWh (AVG)", lt["avgKwh"], s["Usage_kWh"].mean(), 0.005)
        check(f"{lt['key']} total kWh (SUM)", lt["totalKwh"], s["Usage_kWh"].sum(), 0.005)
        check(f"{lt['key']} % of total kWh", lt["pctEnergy"], 100 * s["Usage_kWh"].sum() / u.sum(), 0.005)
        check(f"{lt['key']} avg lagging kVarh (AVG)", lt["avgLaggingKvarh"],
              s["Lagging_Current_Reactive_Power_kVarh"].mean(), 0.005)
        check(f"{lt['key']} avg CO2 (AVG)", lt["avgCo2"], s["CO2_tCO2_"].mean(), 0.00005)
        check(f"{lt['key']} total CO2 (SUM)", lt["totalCo2"], s["CO2_tCO2_"].sum(), 0.005)
        check(f"{lt['key']} avg lagging PF (AVG)", lt["avgLaggingPf"],
              s["Lagging_Current_Power_Factor"].mean(), 0.005)

    c = D["correlations"]
    for key, col in [("usageVsLaggingKvarh", "Lagging_Current_Reactive_Power_kVarh"),
                     ("usageVsCo2", "CO2_tCO2_"),
                     ("usageVsLaggingPf", "Lagging_Current_Power_Factor")]:
        r = np.corrcoef(u, df[col])[0, 1]
        check(f"r {key} (CORR, all intervals)", c[key], r, 0.00005)
        check(f"R² {key} (= r², 3 dp)", D["rSquared"][key], round(r ** 2, 3), 0)

    print(f"\n{sum(results)}/{len(results)} checks passed")
    return 0 if all(results) else 1


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    sys.exit(main(sys.argv[1]))

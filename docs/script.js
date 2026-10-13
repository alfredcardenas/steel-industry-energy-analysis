/* Steel Industry Energy — web dashboard
 * Plain JavaScript, no libraries. Every chart is drawn from window.STEEL_DATA
 * (data/data.js), which holds the validated BigQuery results.
 */
(function () {
  "use strict";

  const D = window.STEEL_DATA;
  const NS = "http://www.w3.org/2000/svg";
  const css = getComputedStyle(document.documentElement);
  const C = {
    blue: css.getPropertyValue("--blue").trim(),
    blue2: css.getPropertyValue("--blue-2").trim(),
    blue3: css.getPropertyValue("--blue-3").trim(),
    grid: css.getPropertyValue("--grid").trim(),
    text: css.getPropertyValue("--text").trim(),
    border: css.getPropertyValue("--border").trim()
  };

  /* ---------- helpers ---------- */
  const fmt2 = (n) => n.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  const fmt0 = (n) => n.toLocaleString("en-US", { maximumFractionDigits: 0 });
  const fmtK = (n) => (n / 1000).toFixed(1) + "k";
  const hh = (h) => String(h).padStart(2, "0") + ":00";

  function svg(tag, attrs, parent) {
    const node = document.createElementNS(NS, tag);
    for (const k in attrs) node.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(node);
    return node;
  }
  function text(parent, x, y, str, cls, anchor) {
    const t = svg("text", { x, y, class: cls || "axis-label", "text-anchor": anchor || "start" }, parent);
    t.textContent = str;
    return t;
  }
  function frame(container) {
    container.innerHTML = "";
    const w = container.clientWidth, h = container.clientHeight;
    const root = svg("svg", { width: w, height: h, viewBox: `0 0 ${w} ${h}` }, container);
    return { root, w, h };
  }

  /* ---------- tooltip ---------- */
  const tip = document.getElementById("tooltip");
  function showTip(evt, html) {
    tip.innerHTML = html;
    tip.classList.add("show");
    const pad = 12, r = tip.getBoundingClientRect();
    let x = evt.clientX + pad, y = evt.clientY - r.height - pad;
    if (x + r.width > window.innerWidth - 8) x = evt.clientX - r.width - pad;
    if (y < 8) y = evt.clientY + pad;
    tip.style.left = x + "px";
    tip.style.top = y + "px";
  }
  function hideTip() { tip.classList.remove("show"); }
  function hover(node, html) {
    node.addEventListener("mousemove", (e) => showTip(e, html));
    node.addEventListener("mouseleave", hideTip);
    node.style.cursor = "default";
  }

  /* ---------- KPIs ---------- */
  function renderKpis() {
    const k = D.kpis;
    const ratio = k.weekdayAvgKwh / k.weekendAvgKwh; // 2.866...
    document.getElementById("kpi-avg").textContent = fmt2(k.avgKwh);
    document.getElementById("kpi-peak-avg").textContent = fmt2(k.peakHourAvgKwh);
    document.getElementById("kpi-peak-hour").textContent = k.peakHour + ":00";
    document.getElementById("kpi-ratio").textContent = ratio.toFixed(1) + "×";

    const c = D.correlations;
    document.getElementById("r-kvarh").textContent = c.usageVsLaggingKvarh.toFixed(3);
    document.getElementById("r-co2").textContent = c.usageVsCo2.toFixed(3);
    document.getElementById("r-pf").textContent = c.usageVsLaggingPf.toFixed(3);
    // R² (share of variance explained by a linear fit) comes precomputed from the raw data
    const r2 = D.rSquared;
    document.getElementById("r2-kvarh").textContent = r2.usageVsLaggingKvarh.toFixed(3);
    document.getElementById("r2-co2").textContent = r2.usageVsCo2.toFixed(3);
    document.getElementById("r2-pf").textContent = r2.usageVsLaggingPf.toFixed(3);

    document.getElementById("week-callout").innerHTML =
      `Weekday average is <strong>${ratio.toFixed(2)}×</strong> the weekend average ` +
      `(${fmt2(k.weekdayAvgKwh)} ÷ ${fmt2(k.weekendAvgKwh)}).`;
  }

  /* ---------- Hourly line chart ---------- */
  function renderHourly() {
    const el = document.getElementById("chart-hourly");
    const { root, w, h } = frame(el);
    const data = D.hourlyAvgKwh;
    const m = { l: 34, r: 14, t: 30, b: 26 };
    const iw = w - m.l - m.r, ih = h - m.t - m.b;
    const yMax = 70;
    const x = (i) => m.l + (i / (data.length - 1)) * iw;
    const y = (v) => m.t + ih - (v / yMax) * ih;

    // horizontal gridlines + y labels
    [0, 20, 40, 60].forEach((v) => {
      svg("line", { x1: m.l, x2: m.l + iw, y1: y(v), y2: y(v), stroke: v === 0 ? C.border : C.grid }, root);
      text(root, m.l - 8, y(v) + 4, v, "axis-label", "end");
    });
    text(root, m.l - 8, m.t - 14, "kWh", "axis-title", "end");

    // x labels every 3 hours
    const step = iw < 500 ? 6 : 3;
    for (let i = 0; i < 24; i += step) text(root, x(i), h - 6, hh(i), "axis-label", "middle");

    // subtle area + line (straight segments: no smoothing between real values)
    const pts = data.map((v, i) => `${x(i)},${y(v)}`);
    svg("path", {
      d: `M${x(0)},${y(0)} L${pts.join(" L")} L${x(23)},${y(0)} Z`,
      fill: C.blue, "fill-opacity": 0.07
    }, root);
    svg("path", {
      d: `M${pts.join(" L")}`, fill: "none", stroke: C.blue,
      "stroke-width": 2.25, "stroke-linejoin": "round", "stroke-linecap": "round"
    }, root);

    // points
    const peakIdx = data.indexOf(Math.max(...data));
    data.forEach((v, i) => {
      if (i === peakIdx) return;
      svg("circle", { cx: x(i), cy: y(v), r: 2.5, fill: C.blue }, root);
    });

    // peak marker + annotation
    const px = x(peakIdx), py = y(data[peakIdx]);
    svg("line", { x1: px, x2: px, y1: py, y2: y(0), stroke: C.blue, "stroke-dasharray": "3 3", "stroke-opacity": 0.5 }, root);
    svg("circle", { cx: px, cy: py, r: 5, fill: "#fff", stroke: C.blue, "stroke-width": 2.5 }, root);
    text(root, px, py - 18, `Peak ${hh(peakIdx)} · ${fmt2(data[peakIdx])} kWh`, "annot", "middle");

    // hover bands
    const band = iw / 23;
    data.forEach((v, i) => {
      const r = svg("rect", { x: x(i) - band / 2, y: m.t, width: band, height: ih, fill: "transparent" }, root);
      hover(r, `<b>${hh(i)}–${String(i).padStart(2, "0")}:59</b><br>${fmt2(v)} kWh avg. per interval`);
    });
  }

  /* ---------- Horizontal bars (HTML) ---------- */
  function renderHBars(id, items, max) {
    const el = document.getElementById(id);
    el.innerHTML = "";
    items.forEach((it) => {
      const row = document.createElement("div");
      row.className = "hbar";
      row.innerHTML =
        `<div class="hbar-head"><span class="hbar-name">${it.label}</span>` +
        `<span class="hbar-value">${fmt2(it.value)}<small>kWh</small></span></div>` +
        `<div class="hbar-track"><div class="hbar-fill" style="width:${(it.value / max) * 100}%"></div></div>`;
      hover(row, it.tip);
      el.appendChild(row);
    });
  }
  function renderLoad() {
    const items = D.loadTypes.map((l) => ({
      label: l.label,
      value: l.avgKwh,
      tip: `<b>${l.key}</b><br>${fmt2(l.avgKwh)} kWh avg. per interval<br>${fmt0(l.records)} intervals (${l.pctRecords}%)`
    }));
    renderHBars("chart-load", items, Math.max(...items.map((i) => i.value)));
  }
  function renderWeek() {
    const k = D.kpis;
    renderHBars("chart-week", [
      { label: "Weekday", value: k.weekdayAvgKwh, tip: `<b>Weekday</b><br>${fmt2(k.weekdayAvgKwh)} kWh avg. per interval<br>${fmt0(k.weekdayRecords)} intervals` },
      { label: "Weekend", value: k.weekendAvgKwh, tip: `<b>Weekend</b><br>${fmt2(k.weekendAvgKwh)} kWh avg. per interval<br>${fmt0(k.weekendRecords)} intervals` }
    ], k.weekdayAvgKwh);
  }

  /* ---------- Monthly vertical bars ---------- */
  function renderMonthly() {
    const el = document.getElementById("chart-monthly");
    const { root, w, h } = frame(el);
    const data = D.monthlyTotalKwh;
    const m = { l: 36, r: 6, t: 30, b: 22 };
    const iw = w - m.l - m.r, ih = h - m.t - m.b;
    const yMax = 140000;
    const y = (v) => m.t + ih - (v / yMax) * ih;
    const slot = iw / data.length, bw = Math.min(30, slot * 0.62);

    [0, 40000, 80000, 120000].forEach((v) => {
      svg("line", { x1: m.l, x2: m.l + iw, y1: y(v), y2: y(v), stroke: v === 0 ? C.border : C.grid }, root);
      text(root, m.l - 8, y(v) + 4, v === 0 ? "0" : v / 1000 + "k", "axis-label", "end");
    });
    text(root, m.l - 8, m.t - 14, "kWh", "axis-title", "end");

    const totals = data.map((d) => d.total);
    const hi = totals.indexOf(Math.max(...totals));
    const lo = totals.indexOf(Math.min(...totals));

    data.forEach((d, i) => {
      const cx = m.l + slot * i + slot / 2;
      const bar = svg("rect", {
        x: cx - bw / 2, y: y(d.total), width: bw, height: y(0) - y(d.total),
        rx: 2, fill: i === hi ? C.blue : C.blue2
      }, root);
      hover(bar, `<b>${d.month} 2018</b><br>${fmt2(d.total)} kWh total`);
      text(root, cx, h - 4, d.month, "axis-label", "middle");
      // On narrow screens the 'Lowest' label would overlap neighbouring bars; tooltip still shows it
      if (i === hi || (i === lo && slot >= 30)) {
        text(root, cx, y(d.total) - 6, fmtK(d.total), "annot", i === hi ? "start" : "middle")
          .setAttribute("x", i === hi ? cx - bw / 2 : cx);
        text(root, i === hi ? cx - bw / 2 : cx, y(d.total) - 20, i === hi ? "Highest" : "Lowest",
          "annot-sub", i === hi ? "start" : "middle");
      }
    });
  }

  /* ---------- 3-point scatter (load-type averages) ---------- */
  function renderScatter(id, xKey, xTitle, xMax, xTicks, xFmt) {
    const el = document.getElementById(id);
    const { root, w, h } = frame(el);
    const pts = D.loadTypes;
    const m = { l: 34, r: 20, t: 26, b: 40 };
    const iw = w - m.l - m.r, ih = h - m.t - m.b;
    const yMax = 70;
    const x = (v) => m.l + (v / xMax) * iw;
    const y = (v) => m.t + ih - (v / yMax) * ih;

    [0, 20, 40, 60].forEach((v) => {
      svg("line", { x1: m.l, x2: m.l + iw, y1: y(v), y2: y(v), stroke: v === 0 ? C.border : C.grid }, root);
      text(root, m.l - 8, y(v) + 4, v, "axis-label", "end");
    });
    text(root, m.l - 8, m.t - 12, "Avg. kWh", "axis-title", "start").setAttribute("x", 0);
    xTicks.forEach((v) => text(root, x(v), m.t + ih + 16, xFmt(v), "axis-label", "middle"));
    text(root, m.l + iw / 2, h - 2, xTitle, "axis-title", "middle");

    pts.forEach((p) => {
      const cx = x(p[xKey]), cy = y(p.avgKwh);
      const dot = svg("circle", { cx, cy, r: 7, fill: C.blue, "fill-opacity": 0.9, stroke: "#fff", "stroke-width": 2 }, root);
      const anchorEnd = cx > m.l + iw * 0.7;
      text(root, cx + (anchorEnd ? -12 : 12), cy + 4, `${p.label} (${fmt2(p.avgKwh)})`, "annot", anchorEnd ? "end" : "start");
      hover(dot, `<b>${p.key}</b><br>${fmt2(p.avgKwh)} kWh avg.<br>${xTitle}: ${xFmt(p[xKey], true)}`);
    });
  }

  /* ---------- Frequency vs energy share ---------- */
  function renderShare() {
    const el = document.getElementById("chart-share");
    const colors = { Light_Load: C.blue3, Medium_Load: C.blue2, Maximum_Load: C.blue };
    const rows = [
      { label: "% of intervals", key: "pctRecords" },
      { label: "% of total kWh", key: "pctEnergy" }
    ];
    el.innerHTML = "";
    rows.forEach((r) => {
      const row = document.createElement("div");
      row.className = "share-row";
      row.innerHTML = `<span class="share-label">${r.label}</span><div class="share-bar"></div>`;
      const bar = row.querySelector(".share-bar");
      D.loadTypes.forEach((l) => {
        const seg = document.createElement("div");
        seg.className = "share-seg" + (l.key === "Light_Load" ? " dark-text" : "");
        seg.style.width = l[r.key] + "%";
        seg.style.background = colors[l.key];
        seg.textContent = l[r.key].toFixed(1) + "%";
        hover(seg, `<b>${l.key}</b><br>${r.label}: ${l[r.key]}%`);
        bar.appendChild(seg);
      });
      el.appendChild(row);
    });
    const legend = document.createElement("div");
    legend.className = "legend";
    legend.innerHTML = D.loadTypes.map((l) => `<span><i style="background:${colors[l.key]}"></i>${l.key}</span>`).join("");
    el.appendChild(legend);
  }

  /* ---------- views ---------- */
  function drawCharts() {
    const detail = !document.getElementById("view-detail").hidden;
    if (detail) {
      renderScatter("chart-kvarh", "avgLaggingKvarh", "Avg. lagging reactive power (kVarh)", 30, [0, 10, 20, 30],
        (v, long) => long ? fmt2(v) + " kVarh" : String(v));
      renderScatter("chart-co2", "avgCo2", "Avg. CO₂ per interval (tCO₂)", 0.03, [0, 0.01, 0.02, 0.03],
        (v, long) => long ? v.toFixed(4) + " tCO₂" : v === 0 ? "0" : v.toFixed(2));
    } else {
      renderHourly();
      renderMonthly();
    }
  }
  function setView(name) {
    document.querySelectorAll(".tab").forEach((t) => t.setAttribute("aria-selected", String(t.dataset.view === name)));
    document.getElementById("view-overview").hidden = name !== "overview";
    document.getElementById("view-detail").hidden = name !== "detail";
    drawCharts();
  }
  document.querySelectorAll(".tab").forEach((t) =>
    t.addEventListener("click", () => {
      history.replaceState(null, "", t.dataset.view === "detail" ? "#detail" : "#overview");
      setView(t.dataset.view);
    })
  );

  renderKpis();
  renderLoad();
  renderWeek();
  renderShare();
  setView(location.hash === "#detail" ? "detail" : "overview");

  let timer;
  window.addEventListener("resize", () => { clearTimeout(timer); timer = setTimeout(drawCharts, 120); });
})();

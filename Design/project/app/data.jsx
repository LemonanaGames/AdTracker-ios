// data.jsx — deterministic mock revenue data for the ad-report prototype
// Exposes window.AppData

(function () {
  // ---- seeded RNG ---------------------------------------------------------
  function hashStr(s) {
    let h = 1779033703 ^ s.length;
    for (let i = 0; i < s.length; i++) {
      h = Math.imul(h ^ s.charCodeAt(i), 3432918353);
      h = (h << 13) | (h >>> 19);
    }
    return h >>> 0;
  }
  function mulberry32(a) {
    return function () {
      a |= 0; a = (a + 0x6D2B79F5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  // ---- date helpers -------------------------------------------------------
  const TODAY = new Date(2026, 5, 15); // June 15 2026
  const NOW_FRACTION = 0.27;           // ~11:31am -> ~27% of the day elapsed/earned
  const MS_DAY = 86400000;
  function addDays(d, n) { return new Date(d.getTime() + n * MS_DAY); }
  function ymd(d) { return d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate(); }
  const MONTHS = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  const MON_S = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  const DOW = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
  function fmtDate(d) { return d.getDate() + ' ' + MONTHS[d.getMonth()] + ' ' + d.getFullYear(); }
  function fmtDateShort(d) { return MON_S[d.getMonth()] + ' ' + d.getDate(); }

  // ---- networks & accounts ------------------------------------------------
  const NETWORKS = {
    applovin: { id: 'applovin', name: 'AppLovin Max', short: 'AppLovin', base: 4400, vol: 0.22, color: '#7B5BF5' },
    admob:    { id: 'admob',    name: 'Google AdMob', short: 'AdMob',    base: 1850, vol: 0.18, color: '#34A853' },
  };

  // apps catalog — each has stable monetization characteristics
  const APPS = [
    { id: 'tod',   name: 'Truth or Dare', platform: 'iOS',     weight: 34, ecpm: 16.5, ctr: 0.018, matchRate: 0.82, hue: 330 },
    { id: 'taino', name: 'Taino VPN',     platform: 'Android', weight: 26, ecpm: 9.2,  ctr: 0.011, matchRate: 0.74, hue: 212 },
    { id: 'sera',  name: 'Sera',          platform: 'iOS',     weight: 18, ecpm: 21.0, ctr: 0.022, matchRate: 0.88, hue: 265 },
    { id: 'pulse', name: 'Pulse Tracker', platform: 'iOS',     weight: 13, ecpm: 13.0, ctr: 0.014, matchRate: 0.80, hue: 150 },
    { id: 'lumio', name: 'Lumio',         platform: 'Android', weight: 9,  ecpm: 7.5,  ctr: 0.009, matchRate: 0.70, hue: 35 },
  ];
  const COUNTRIES = [
    { id: 'US', name: 'United States', flag: '\uD83C\uDDFA\uD83C\uDDF8', weight: 38, em: 1.6 },
    { id: 'PH', name: 'Philippines',   flag: '\uD83C\uDDF5\uD83C\uDDED', weight: 14, em: 0.55 },
    { id: 'IN', name: 'India',         flag: '\uD83C\uDDEE\uD83C\uDDF3', weight: 12, em: 0.42 },
    { id: 'BR', name: 'Brazil',        flag: '\uD83C\uDDE7\uD83C\uDDF7', weight: 10, em: 0.6 },
    { id: 'GB', name: 'United Kingdom',flag: '\uD83C\uDDEC\uD83C\uDDE7', weight: 9,  em: 1.5 },
    { id: 'DE', name: 'Germany',       flag: '\uD83C\uDDE9\uD83C\uDDEA', weight: 7,  em: 1.4 },
    { id: 'XX', name: 'Other',         flag: '\uD83C\uDF10',             weight: 10, em: 0.7 },
  ];
  const ADUNITS = [
    { id: 'inter',    name: 'Interstitial', weight: 34, em: 1.2 },
    { id: 'rewarded', name: 'Rewarded',     weight: 30, em: 1.55 },
    { id: 'banner',   name: 'Banner',       weight: 21, em: 0.35 },
    { id: 'native',   name: 'Native',       weight: 10, em: 0.9 },
    { id: 'appopen',  name: 'App Open',     weight: 5,  em: 1.05 },
  ];

  const ACCOUNTS = [
    { id: 'main',  name: 'Main Studio',  networks: ['applovin', 'admob'], mult: 1.0,  apps: ['tod', 'taino', 'sera', 'pulse', 'lumio'] },
    { id: 'hyper', name: 'Hyper Games',  networks: ['applovin'],          mult: 0.42, apps: ['pulse', 'lumio'] },
    { id: 'casual',name: 'Casual Labs',  networks: ['admob'],             mult: 0.65, apps: ['taino', 'sera'] },
  ];

  // ---- series generation --------------------------------------------------
  const HISTORY = 120; // days of history
  function buildSeries(accountId, networkId, mult) {
    const net = NETWORKS[networkId];
    const rnd = mulberry32(hashStr(accountId + ':' + networkId));
    const out = [];
    for (let i = HISTORY - 1; i >= 0; i--) {
      const date = addDays(TODAY, -i);
      const dow = date.getDay();
      // weekly seasonality: weekends slightly lower for these genres
      const wk = (dow === 0 || dow === 6) ? 0.88 : 1.0 + (dow === 3 ? 0.06 : 0);
      // gentle upward trend over time
      const trend = 1 + (HISTORY - i) / HISTORY * 0.35;
      // monthly wobble
      const wave = 1 + Math.sin((HISTORY - i) / 9) * 0.07;
      const noise = 1 + (rnd() - 0.5) * net.vol * 2;
      let value = net.base * mult * wk * trend * wave * noise;
      const isToday = i === 0;
      if (isToday) value *= NOW_FRACTION;
      out.push({ date, value: Math.max(0, value), partial: isToday });
    }
    return out;
  }

  // precompute series for every account/network pair
  const SERIES = {};
  ACCOUNTS.forEach(acc => {
    acc.networks.forEach(nid => {
      SERIES[acc.id + ':' + nid] = buildSeries(acc.id, nid, acc.mult);
    });
  });

  // ---- query helpers ------------------------------------------------------
  function series(accountId, networkId) { return SERIES[accountId + ':' + networkId] || []; }

  // combined daily series across an account's networks
  function accountSeries(accountId) {
    const acc = ACCOUNTS.find(a => a.id === accountId);
    const len = HISTORY;
    const out = [];
    for (let i = 0; i < len; i++) {
      let v = 0, date = null, partial = false;
      acc.networks.forEach(nid => {
        const s = series(accountId, nid)[i];
        if (s) { v += s.value; date = s.date; partial = s.partial; }
      });
      out.push({ date, value: v, partial });
    }
    return out;
  }

  // last N days (most recent last). includes today (partial)
  function lastN(arr, n) { return arr.slice(arr.length - n); }
  function sumN(arr, n) { return lastN(arr, n).reduce((a, b) => a + b.value, 0); }
  function valueToday(arr) { return arr[arr.length - 1].value; }

  // week (Mon-Sun) / month / year aggregations from a daily series
  function aggregate(arr, kind) {
    const groups = {};
    arr.forEach(d => {
      let key, label, sort;
      const dt = d.date;
      if (kind === 'weekly') {
        const day = (dt.getDay() + 6) % 7; // Mon=0
        const monday = addDays(dt, -day);
        key = ymd(monday);
        label = 'Week of ' + fmtDateShort(monday);
        sort = monday.getTime();
      } else if (kind === 'monthly') {
        key = dt.getFullYear() + '-' + dt.getMonth();
        label = MONTHS[dt.getMonth()] + ' ' + dt.getFullYear();
        sort = dt.getFullYear() * 12 + dt.getMonth();
      } else { // yearly
        key = '' + dt.getFullYear();
        label = '' + dt.getFullYear();
        sort = dt.getFullYear();
      }
      if (!groups[key]) groups[key] = { key, label, value: 0, sort, partial: false };
      groups[key].value += d.value;
      if (d.partial) groups[key].partial = true;
    });
    return Object.values(groups).sort((a, b) => b.sort - a.sort);
  }

  // ---- goals --------------------------------------------------------------
  const GOALS = { daily: 7000, weekly: 42000, monthly: 175000, yearly: 2000000 };

  // ---- formatting ---------------------------------------------------------
  function money(n, opts) {
    opts = opts || {};
    const dp = opts.dp != null ? opts.dp : 2;
    return '$' + n.toLocaleString('en-US', { minimumFractionDigits: dp, maximumFractionDigits: dp });
  }
  function moneyK(n) {
    if (n >= 1e6) return '$' + (n / 1e6).toFixed(2) + 'M';
    if (n >= 1e4) return '$' + (n / 1e3).toFixed(1) + 'K';
    return '$' + Math.round(n).toLocaleString('en-US');
  }
  function pct(n) { return (n >= 0 ? '+' : '') + n.toFixed(1) + '%'; }
  function compact(n) {
    n = Math.round(n);
    if (n >= 1e6) return (n / 1e6).toFixed(2).replace(/\.?0+$/, '') + 'M';
    if (n >= 1e3) return (n / 1e3).toFixed(1).replace(/\.0$/, '') + 'k';
    return n.toLocaleString('en-US');
  }

  // ---- period revenue + metrics ------------------------------------------
  const PERIODS = [
    { id: 'today', label: 'Today', cmp: 'same day last week' },
    { id: 'yesterday', label: 'Yesterday', cmp: 'prev day' },
    { id: 'last7', label: 'Last 7 days', cmp: 'prev 7 days' },
    { id: 'thismonth', label: 'This month', cmp: 'last month' },
    { id: 'lastmonth', label: 'Last month', cmp: 'prior month' },
  ];
  function monthSum(cmb, monthOffset) {
    const base = new Date(TODAY.getFullYear(), TODAY.getMonth() + monthOffset, 1);
    let s = 0; cmb.forEach(d => { if (d.date.getMonth() === base.getMonth() && d.date.getFullYear() === base.getFullYear()) s += d.value; });
    return s;
  }
  function periodRevenue(accId, period) {
    const cmb = accountSeries(accId); const L = cmb.length - 1;
    switch (period) {
      case 'today': return cmb[L].value;
      case 'yesterday': return cmb[L - 1].value;
      case 'last7': return sumN(cmb, 7);
      case 'thismonth': return monthSum(cmb, 0);
      case 'lastmonth': return monthSum(cmb, -1);
      default: return cmb[L].value;
    }
  }
  function periodDelta(accId, period) {
    const cmb = accountSeries(accId); const L = cmb.length - 1;
    let cur, prev;
    if (period === 'today') { cur = cmb[L].value / NOW_FRACTION; prev = cmb[L - 7].value; }
    else if (period === 'yesterday') { cur = cmb[L - 1].value; prev = cmb[L - 8].value; }
    else if (period === 'last7') { cur = sumN(cmb, 7); prev = cmb.slice(L - 13, L - 6).reduce((a, b) => a + b.value, 0); }
    else if (period === 'thismonth') { cur = monthSum(cmb, 0); prev = monthSum(cmb, -1) * (TODAY.getDate() / 30); }
    else { cur = monthSum(cmb, -1); prev = monthSum(cmb, -2) || cur * 0.9; }
    if (!prev) return 0;
    return (cur - prev) / prev * 100;
  }

  // per-app metrics for an account & period
  function appMetrics(accId, period) {
    const acc = ACCOUNTS.find(a => a.id === accId);
    const apps = (acc.apps || []).map(id => APPS.find(a => a.id === id));
    const rev = periodRevenue(accId, period);
    const tw = apps.reduce((s, a) => s + a.weight, 0);
    return apps.map(a => {
      const earnings = rev * a.weight / tw;
      const impressions = earnings / a.ecpm * 1000;
      const clicks = impressions * a.ctr;
      const requests = impressions / a.matchRate;
      return { app: a, earnings, impressions, clicks, requests, matched: impressions, ecpm: a.ecpm, ctr: a.ctr * 100, matchRate: a.matchRate * 100 };
    }).sort((x, y) => y.earnings - x.earnings);
  }
  function totals(rows) {
    const t = { earnings: 0, impressions: 0, clicks: 0, requests: 0, matched: 0 };
    rows.forEach(r => { t.earnings += r.earnings; t.impressions += r.impressions; t.clicks += r.clicks; t.requests += r.requests; t.matched += r.matched; });
    t.ecpm = t.impressions ? t.earnings / t.impressions * 1000 : 0;
    t.ctr = t.impressions ? t.clicks / t.impressions * 100 : 0;
    t.matchRate = t.requests ? t.matched / t.requests * 100 : 0;
    return t;
  }
  // split a totals object across a catalog (countries / ad units), varying eCPM
  function splitBy(tot, catalog) {
    const tw = catalog.reduce((s, c) => s + c.weight, 0);
    return catalog.map(c => {
      const earnings = tot.earnings * c.weight / tw;
      const ecpm = tot.ecpm * (c.em || 1);
      const impressions = ecpm ? earnings / ecpm * 1000 : 0;
      const clicks = impressions * (tot.ctr / 100);
      const requests = impressions / (tot.matchRate / 100 || 0.8);
      return { item: c, earnings, impressions, clicks, requests, ecpm, ctr: tot.ctr, matchRate: tot.matchRate };
    }).sort((x, y) => y.earnings - x.earnings);
  }
  const METRICS = [
    { id: 'earnings', label: 'Earnings', short: 'Earnings', icon: 'dollar' },
    { id: 'clicks', label: 'Clicks', short: 'Clicks', icon: 'cursor' },
    { id: 'impressions', label: 'Impressions', short: 'Impr.', icon: 'eye' },
    { id: 'matchRate', label: 'Match Rate', short: 'Match', icon: 'pulse' },
    { id: 'matched', label: 'Matched Requests', short: 'Matched', icon: 'chart' },
    { id: 'ctr', label: 'Impression CTR', short: 'CTR', icon: 'pie' },
    { id: 'requests', label: 'Ad Requests', short: 'Requests', icon: 'mega' },
    { id: 'ecpm', label: 'Observed eCPM', short: 'eCPM', icon: 'coin' },
  ];
  function fmtMetric(metric, v) {
    switch (metric) {
      case 'earnings': case 'ecpm': return money(v);
      case 'ctr': return v.toFixed(2) + '%';
      case 'matchRate': return v.toFixed(0) + '%';
      default: return compact(v);
    }
  }

  window.AppData = {
    TODAY, NOW_FRACTION, MONTHS, MON_S, DOW,
    NETWORKS, ACCOUNTS, GOALS, APPS, COUNTRIES, ADUNITS, PERIODS, METRICS,
    series, accountSeries, lastN, sumN, valueToday, aggregate,
    addDays, ymd, fmtDate, fmtDateShort,
    money, moneyK, pct, compact, hashStr,
    periodRevenue, periodDelta, appMetrics, totals, splitBy, fmtMetric,
  };
})();

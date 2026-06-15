// screens-more.jsx — Goals, Analytics, Accounts, Notifications, Settings, Configure, Paywall
(function () {
  const { useState, useMemo } = React;
  const D = window.AppData;
  const { NetBadge, Card, BarChart, Sparkline, Ring, Segmented, Delta, SectionTitle } = window.UI;

  // period stats from a combined daily series
  function periodStats(combined) {
    const today = combined[combined.length - 1];
    const dt = today.date;
    // weekly (Mon start)
    const dowMon = (dt.getDay() + 6) % 7;
    let wk = 0; for (let i = 0; i <= dowMon; i++) wk += combined[combined.length - 1 - i].value;
    const wkFrac = (dowMon + D.NOW_FRACTION) / 7;
    // monthly
    const dom = dt.getDate();
    let mo = 0; for (let i = 0; i < dom; i++) mo += combined[combined.length - 1 - i].value;
    const daysInMonth = new Date(dt.getFullYear(), dt.getMonth() + 1, 0).getDate();
    const moFrac = (dom - 1 + D.NOW_FRACTION) / daysInMonth;
    // yearly
    const startYear = new Date(dt.getFullYear(), 0, 1);
    const doy = Math.round((dt - startYear) / 86400000) + 1;
    let yr = 0; for (let i = 0; i < combined.length; i++) { if (combined[i].date >= startYear) yr += combined[i].value; }
    const yrFrac = (doy - 1 + D.NOW_FRACTION) / 365;
    return {
      daily: { cur: today.value, goal: D.GOALS.daily, frac: D.NOW_FRACTION, label: 'Today' },
      weekly: { cur: wk, goal: D.GOALS.weekly, frac: wkFrac, label: 'This week' },
      monthly: { cur: mo, goal: D.GOALS.monthly, frac: moFrac, label: D.MONTHS[dt.getMonth()] },
      yearly: { cur: yr, goal: D.GOALS.yearly, frac: yrFrac, label: '' + dt.getFullYear() },
    };
  }

  // ───────────────────────────── Goals ─────────────────────────────
  function Goals() {
    const t = window.useT();
    const nav = window.useNav();
    const acc = nav.accountObj;
    const combined = useMemo(() => D.accountSeries(acc.id), [acc.id]);
    const st = useMemo(() => periodStats(combined), [combined]);
    const G = D.GOALS;
    const d = st.daily, dPct = d.cur / G.daily;
    const proj = d.cur / d.frac;
    const onPace = proj >= G.daily;

    const periodCard = (s, key) => {
      const pct = Math.min(1, s.cur / s.goal);
      const projP = s.cur / s.frac;
      const hit = projP >= s.goal;
      return (
        <Card key={key} style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          <Ring value={s.cur} goal={s.goal} size={62} sw={7} color={hit ? t.pos : t.accent}>
            <span style={{ fontSize: 13, fontWeight: 800, color: t.text }}>{Math.round(pct * 100)}%</span>
          </Ring>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
              <span style={{ fontSize: 15.5, fontWeight: 700, color: t.text, textTransform: 'capitalize' }}>{key}</span>
              <span style={{ fontSize: 13, color: t.sec }}>{s.label}</span>
            </div>
            <div style={{ fontSize: 14, color: t.sec, marginTop: 3 }}>
              <span style={{ color: t.text, fontWeight: 700 }}>{D.moneyK(s.cur)}</span> of {D.moneyK(s.goal)}
            </div>
            <div style={{ fontSize: 12.5, color: hit ? t.pos : t.ter, marginTop: 2, fontWeight: 600 }}>
              {hit ? '✓ On pace' : 'Projected ' + D.moneyK(projP)}
            </div>
          </div>
          <button onClick={() => nav.push({ type: 'editGoal', period: key })} style={{ border: 'none', background: t.card2, borderRadius: 999, width: 32, height: 32, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
            <Icon name="chevron" s={15} c={t.sec} />
          </button>
        </Card>
      );
    };

    return (
      <div style={{ padding: '0 16px 24px' }}>
        {/* hero daily ring */}
        <Card style={{ marginBottom: 18, display: 'flex', flexDirection: 'column', alignItems: 'center', paddingTop: 26, paddingBottom: 24 }}>
          <Ring value={d.cur} goal={G.daily} size={196} sw={18} color={onPace ? t.pos : t.accent}>
            <div style={{ fontSize: 12, fontWeight: 700, color: t.ter, letterSpacing: 0.5 }}>TODAY</div>
            <div style={{ fontSize: 34, fontWeight: 800, color: t.text, letterSpacing: -1, marginTop: 2 }}>{D.money(d.cur, { dp: 0 })}</div>
            <div style={{ fontSize: 13, color: t.sec, marginTop: 2 }}>of {D.moneyK(G.daily)} goal</div>
          </Ring>
          <div style={{ marginTop: 18, textAlign: 'center' }}>
            <div style={{ fontSize: 20, fontWeight: 800, color: onPace ? t.pos : t.text }}>{Math.round(dPct * 100)}% complete</div>
            <div style={{ fontSize: 14, color: t.sec, marginTop: 3 }}>
              {onPace
                ? `On track — pacing to ${D.moneyK(proj)} today`
                : `${D.money(G.daily - d.cur, { dp: 0 })} to go · pacing ${D.moneyK(proj)}`}
            </div>
          </div>
        </Card>

        {/* streak */}
        <Card style={{ marginBottom: 18, display: 'flex', alignItems: 'center', gap: 14, background: t.dark ? 'linear-gradient(120deg, rgba(255,159,67,0.14), ' + t.card + ' 60%)' : t.card }}>
          <div style={{ width: 46, height: 46, borderRadius: 14, background: 'rgba(255,159,67,0.16)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon name="flame" s={24} c="#ff9f43" />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 16, fontWeight: 700, color: t.text }}>12-day goal streak 🔥</div>
            <div style={{ fontSize: 13.5, color: t.sec, marginTop: 1 }}>You've hit your daily goal 12 days running</div>
          </div>
        </Card>

        <SectionTitle action="Edit" onAction={() => nav.push({ type: 'editGoal', period: 'daily' })}>All goals</SectionTitle>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {periodCard(st.weekly, 'weekly')}
          {periodCard(st.monthly, 'monthly')}
          {periodCard(st.yearly, 'yearly')}
        </div>
      </div>
    );
  }

  // ───────────────────────────── Edit Goal (sheet) ─────────────────────────────
  function EditGoal({ period }) {
    const t = window.useT();
    const nav = window.useNav();
    const [val, setVal] = useState(D.GOALS[period]);
    const steps = { daily: 250, weekly: 1000, monthly: 5000, yearly: 50000 };
    const step = steps[period];
    const save = () => { D.GOALS[period] = val; nav.pop(); };
    return (
      <div style={{ padding: '8px 20px 28px', textAlign: 'center' }}>
        <div style={{ fontSize: 15, color: t.sec, textTransform: 'capitalize', marginTop: 10 }}>{period} goal</div>
        <div style={{ fontSize: 56, fontWeight: 800, color: t.text, letterSpacing: -2, margin: '14px 0' }}>{D.money(val, { dp: 0 })}</div>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 18, marginBottom: 28 }}>
          <button onClick={() => setVal(v => Math.max(step, v - step))} style={stepBtn(t)}>–</button>
          <div style={{ fontSize: 14, color: t.ter, minWidth: 90 }}>±{D.moneyK(step)}</div>
          <button onClick={() => setVal(v => v + step)} style={stepBtn(t)}>+</button>
        </div>
        <input type="range" min={step} max={D.GOALS[period] * 3} step={step} value={val}
          onChange={e => setVal(+e.target.value)}
          style={{ width: '100%', accentColor: t.accent, marginBottom: 28 }} />
        <button onClick={save} style={primaryBtn(t)}>Save goal</button>
      </div>
    );
  }
  function stepBtn(t) {
    return { width: 52, height: 52, borderRadius: 999, border: 'none', cursor: 'pointer', background: t.card2, color: t.text, fontSize: 28, fontWeight: 400, fontFamily: 'inherit' };
  }
  function primaryBtn(t) {
    return { width: '100%', padding: '15px', borderRadius: 16, border: 'none', cursor: 'pointer', background: t.accent, color: t.accentText, fontSize: 17, fontWeight: 700, fontFamily: 'inherit' };
  }

  // ───────────────────────────── Analytics ─────────────────────────────
  function Analytics() {
    const t = window.useT();
    const nav = window.useNav();
    const acc = nav.accountObj;
    const combined = useMemo(() => D.accountSeries(acc.id), [acc.id]);

    const this30 = D.sumN(combined, 30);
    const prev30 = combined.slice(combined.length - 60, combined.length - 30).reduce((a, b) => a + b.value, 0);
    const d30delta = (this30 - prev30) / prev30 * 100;
    const this7 = D.sumN(combined, 7);
    const prev7 = combined.slice(combined.length - 14, combined.length - 7).reduce((a, b) => a + b.value, 0);
    const d7delta = (this7 - prev7) / prev7 * 100;

    const full = combined.slice(0, combined.length - 1); // exclude partial today
    const best = full.reduce((a, b) => b.value > a.value ? b : a, full[0]);
    const avg = D.sumN(combined, 30) / 30;
    const projMonth = avg * new Date(D.TODAY.getFullYear(), D.TODAY.getMonth() + 1, 0).getDate();

    // network split (30d)
    const split = acc.networks.map(nid => ({
      net: D.NETWORKS[nid],
      val: D.sumN(D.series(acc.id, nid), 30),
    }));
    const splitTotal = split.reduce((a, b) => a + b.val, 0);

    // day-of-week averages
    const dowSum = [0, 0, 0, 0, 0, 0, 0], dowCnt = [0, 0, 0, 0, 0, 0, 0];
    full.forEach(d => { const k = d.date.getDay(); dowSum[k] += d.value; dowCnt[k]++; });
    const dowAvg = dowSum.map((s, i) => s / (dowCnt[i] || 1));
    const order = [1, 2, 3, 4, 5, 6, 0];

    const [bp, setBp] = useState('last7');
    const BK = window.BK;
    const appRows = D.appMetrics(acc.id, bp);
    const tot = D.totals(appRows);
    const appItems = appRows.map(r => ({ id: r.app.id, lead: <BK.AppIcon app={r.app} s={38} />, name: r.app.name, sub: r.app.platform + ' · eCPM ' + D.money(r.ecpm), m: BK.toM(r) }));
    const unitItems = D.splitBy(tot, D.ADUNITS).map(u => ({ id: u.item.id, lead: <BK.UnitTile />, name: u.item.name, m: BK.toM(u) }));
    const countryItems = D.splitBy(tot, D.COUNTRIES).map(c => ({ id: c.item.id, lead: <BK.FlagTile flag={c.item.flag} />, name: c.item.name, m: BK.toM(c) }));
    const breakdownMetrics = [{ id: 'earnings', label: 'Earnings' }, { id: 'clicks', label: 'Clicks' }, { id: 'impressions', label: 'Impr.' }, { id: 'requests', label: 'Requests' }, { id: 'ecpm', label: 'eCPM' }];

    const stat = (label, value, sub) => (
      <Card key={label} style={{ flex: 1 }}>
        <div style={{ fontSize: 12.5, color: t.sec, fontWeight: 600 }}>{label}</div>
        <div style={{ fontSize: 21, fontWeight: 800, color: t.text, letterSpacing: -0.6, marginTop: 6 }}>{value}</div>
        {sub && <div style={{ fontSize: 12, color: t.ter, marginTop: 2 }}>{sub}</div>}
      </Card>
    );

    return (
      <div style={{ padding: '0 16px 24px' }}>
        {/* trend cards */}
        <div style={{ display: 'flex', gap: 12, marginBottom: 12 }}>
          <Card style={{ flex: 1 }}>
            <div style={{ fontSize: 12.5, color: t.sec, fontWeight: 600, marginBottom: 8 }}>LAST 7 DAYS</div>
            <div style={{ fontSize: 22, fontWeight: 800, color: t.text, letterSpacing: -0.6 }}>{D.moneyK(this7)}</div>
            <div style={{ marginTop: 8 }}><Delta v={d7delta} sub="vs prev" /></div>
          </Card>
          <Card style={{ flex: 1 }}>
            <div style={{ fontSize: 12.5, color: t.sec, fontWeight: 600, marginBottom: 8 }}>LAST 30 DAYS</div>
            <div style={{ fontSize: 22, fontWeight: 800, color: t.text, letterSpacing: -0.6 }}>{D.moneyK(this30)}</div>
            <div style={{ marginTop: 8 }}><Delta v={d30delta} sub="vs prev" /></div>
          </Card>
        </div>

        {/* network split */}
        <SectionTitle>Network split · 30d</SectionTitle>
        <Card style={{ marginBottom: 22 }}>
          <div style={{ display: 'flex', height: 14, borderRadius: 7, overflow: 'hidden', marginBottom: 16 }}>
            {split.map((s, i) => (
              <div key={i} style={{ width: (s.val / splitTotal * 100) + '%', background: i === 0 ? t.accent : (t.dark ? '#5b6df5' : '#34A853') }} />
            ))}
          </div>
          {split.map((s, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: i ? 12 : 0 }}>
              <NetBadge net={s.net} s={30} />
              <div style={{ flex: 1, fontSize: 15, fontWeight: 600, color: t.text }}>{s.net.name}</div>
              <div style={{ fontSize: 13, color: t.sec, marginRight: 10 }}>{(s.val / splitTotal * 100).toFixed(0)}%</div>
              <div style={{ fontSize: 15, fontWeight: 700, color: t.text }}>{D.moneyK(s.val)}</div>
            </div>
          ))}
        </Card>

        {/* stat grid */}
        <SectionTitle>Highlights</SectionTitle>
        <div style={{ display: 'flex', gap: 12, marginBottom: 12 }}>
          {stat('Best day', D.moneyK(best.value), D.fmtDateShort(best.date))}
          {stat('Avg / day', D.moneyK(avg), 'last 30 days')}
        </div>
        <div style={{ display: 'flex', gap: 12, marginBottom: 22 }}>
          {stat('Top network', split.slice().sort((a, b) => b.val - a.val)[0].net.short, 'by revenue')}
          {stat('Proj. month', D.moneyK(projMonth), 'at current pace')}
        </div>

        {/* day of week */}
        <SectionTitle>By day of week</SectionTitle>
        <Card style={{ marginBottom: 24 }}>
          <BarChart data={order.map(i => ({ value: dowAvg[i] }))} labels={order.map(i => D.DOW[i])} h={120} />
          <div style={{ fontSize: 12.5, color: t.ter, marginTop: 12, textAlign: 'center' }}>Average revenue per weekday · last {Math.round(full.length)} days</div>
        </Card>

        {/* breakdowns by app / ad unit / country */}
        <SectionTitle>Breakdown</SectionTitle>
        <div style={{ marginBottom: 18 }}><BK.PillTabs options={D.PERIODS} value={bp} onChange={setBp} /></div>
        <BK.Breakdown title="Apps" icon="apps" items={appItems} metricOptions={breakdownMetrics}
          onRow={(r) => nav.push({ type: 'app', appId: r.id })} />
        <BK.Breakdown title="Ad Units" icon="layers" items={unitItems} metricOptions={breakdownMetrics} />
        <BK.Breakdown title="Countries" icon="globe" items={countryItems} metricOptions={breakdownMetrics} />
      </div>
    );
  }

  // ───────────────────────────── Accounts (sheet) ─────────────────────────────
  function Accounts() {
    const t = window.useT();
    const nav = window.useNav();
    return (
      <div style={{ padding: '4px 16px 28px' }}>
        <div style={{ fontSize: 14, color: t.sec, margin: '6px 4px 14px' }}>Track revenue across multiple studios and ad accounts. Each account powers its own widgets.</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {D.ACCOUNTS.map(a => {
            const cmb = D.accountSeries(a.id);
            const today = D.valueToday(cmb);
            const sel = a.id === nav.account;
            return (
              <Card key={a.id} onClick={() => { nav.setAccount(a.id); nav.pop(); }} style={{ cursor: 'pointer', border: sel ? `1.5px solid ${t.accent}` : `1.5px solid transparent`, display: 'flex', alignItems: 'center', gap: 14 }}>
                <div style={{ display: 'flex' }}>
                  {a.networks.map((nid, i) => (
                    <div key={nid} style={{ marginLeft: i ? -10 : 0, border: `2px solid ${t.card}`, borderRadius: 12 }}>
                      <NetBadge net={D.NETWORKS[nid]} s={36} r={10} />
                    </div>
                  ))}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 16, fontWeight: 700, color: t.text }}>{a.name}</div>
                  <div style={{ fontSize: 13, color: t.sec, marginTop: 1 }}>{a.networks.length} network{a.networks.length > 1 ? 's' : ''} · {D.money(today, { dp: 0 })} today</div>
                </div>
                {sel
                  ? <div style={{ width: 26, height: 26, borderRadius: 999, background: t.accent, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Icon name="check" s={15} c={t.accentText} sw={3} /></div>
                  : <div style={{ width: 26, height: 26, borderRadius: 999, border: `2px solid ${t.hair}` }} />}
              </Card>
            );
          })}
        </div>
        <button onClick={() => nav.push({ type: 'configure', adding: true })} style={{ ...primaryBtn(t), marginTop: 18, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, background: t.card, color: t.accent }}>
          <Icon name="plus" s={20} c={t.accent} /> Add account
        </button>
      </div>
    );
  }

  window.Screens = Object.assign(window.Screens || {}, { Goals, EditGoal, Analytics, Accounts, periodStats, primaryBtn });
})();

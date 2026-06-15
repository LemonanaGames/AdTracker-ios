// screens-core.jsx — Dashboard, NetworkDetail, Reports. Exposes window.Screens (partial)
(function () {
  const { useState, useMemo } = React;
  const D = window.AppData;
  const { NetBadge, Card, BarChart, Sparkline, Ring, Segmented, Delta, SectionTitle } = window.UI;

  function greeting() {
    return 'Good morning';
  }

  // tiny helper: three-column overview tile row (Today / 7d / 30d)
  function OverviewTiles({ series }) {
    const t = window.useT();
    const today = D.valueToday(series);
    const d7 = D.sumN(series, 7);
    const d30 = D.sumN(series, 30);
    const cells = [
      { k: 'TODAY', v: D.money(today) },
      { k: '7 DAYS', v: D.money(d7) },
      { k: '30 DAYS', v: D.money(d30) },
    ];
    return (
      <Card pad={0} style={{ display: 'flex', overflow: 'hidden' }}>
        {cells.map((c, i) => (
          <div key={c.k} style={{ flex: 1, padding: '16px 12px', borderLeft: i ? `1px solid ${t.hair}` : 'none', textAlign: 'center' }}>
            <div style={{ fontSize: 11.5, fontWeight: 700, color: t.accent, letterSpacing: 0.4 }}>{c.k}</div>
            <div style={{ fontSize: 19, fontWeight: 700, color: t.text, marginTop: 6, letterSpacing: -0.5, lineHeight: 1.1 }}>{c.v}</div>
          </div>
        ))}
      </Card>
    );
  }

  // ───────────────────────────── Dashboard ─────────────────────────────
  function Dashboard() {
    const t = window.useT();
    const nav = window.useNav();
    const acc = nav.accountObj;
    const combined = useMemo(() => D.accountSeries(acc.id), [acc.id]);
    const today = D.valueToday(combined);
    const yesterday = combined[combined.length - 2].value;
    const projToday = today / D.NOW_FRACTION;
    const deltaVsYest = (projToday - yesterday) / yesterday * 100;
    const last7 = D.lastN(combined, 7);
    const chartData = last7.map((d, i) => ({ value: d.value, dim: d.partial }));
    const labels = last7.map(d => D.DOW[d.date.getDay()][0]);
    const goalPct = today / D.GOALS.daily;

    return (
      <div style={{ padding: '0 16px 24px' }}>
        {/* account switcher + greeting */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 }}>
          <div style={{ fontSize: 15, color: t.sec, fontWeight: 500 }}>{greeting()}</div>
          <button onClick={() => nav.push({ type: 'accounts' })} style={{
            display: 'flex', alignItems: 'center', gap: 5, border: 'none', cursor: 'pointer',
            background: t.card, borderRadius: 999, padding: '6px 8px 6px 12px', color: t.text,
            fontWeight: 600, fontSize: 14, fontFamily: 'inherit',
          }}>
            {acc.name}
            <Icon name="chevronD" s={14} c={t.sec} />
          </button>
        </div>

        {/* hero total */}
        <div style={{ marginBottom: 18 }}>
          <div style={{ fontSize: 13, fontWeight: 700, color: t.ter, letterSpacing: 0.5, textTransform: 'uppercase' }}>Today so far</div>
          <div style={{ fontSize: 52, fontWeight: 800, color: t.text, letterSpacing: -2, lineHeight: 1.05, marginTop: 2 }}>{D.money(today)}</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 8 }}>
            <Delta v={deltaVsYest} />
            <span style={{ fontSize: 13.5, color: t.ter }}>vs yesterday · pace {D.moneyK(projToday)}</span>
          </div>
        </div>

        {/* daily goal progress */}
        <Card onClick={() => nav.setTab('goals')} style={{ marginBottom: 18, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 16 }}>
          <Ring value={today} goal={D.GOALS.daily} size={64} sw={7}>
            <span style={{ fontSize: 14, fontWeight: 800, color: t.text }}>{Math.round(goalPct * 100)}%</span>
          </Ring>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 700, color: t.text }}>Daily goal</div>
            <div style={{ fontSize: 13.5, color: t.sec, marginTop: 2 }}>{D.money(D.GOALS.daily - today, { dp: 0 })} to go · target {D.moneyK(D.GOALS.daily)}</div>
          </div>
          <Icon name="chevron" s={18} c={t.ter} />
        </Card>

        {/* 7-day chart */}
        <Card style={{ marginBottom: 18 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
            <span style={{ fontSize: 12.5, fontWeight: 700, color: t.sec, letterSpacing: 0.5 }}>LAST 7 DAYS</span>
            <span style={{ fontSize: 13, fontWeight: 600, color: t.text }}>{D.money(D.sumN(combined, 7), { dp: 0 })}</span>
          </div>
          <BarChart data={chartData} labels={labels} h={130} />
        </Card>

        {/* overview tiles */}
        <SectionTitle>Overview</SectionTitle>
        <div style={{ marginBottom: 22 }}><OverviewTiles series={combined} /></div>

        {/* networks */}
        <SectionTitle>Networks</SectionTitle>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {acc.networks.map(nid => {
            const net = D.NETWORKS[nid];
            const s = D.series(acc.id, nid);
            const nToday = D.valueToday(s);
            const share = nToday / today * 100;
            const spark = D.lastN(s, 14).map(d => d.value);
            return (
              <Card key={nid} onClick={() => nav.push({ type: 'network', nid })} style={{ cursor: 'pointer' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                  <NetBadge net={net} s={40} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 16, fontWeight: 700, color: t.text }}>{net.name}</div>
                    <div style={{ fontSize: 13, color: t.sec, marginTop: 1 }}>{share.toFixed(0)}% of today</div>
                  </div>
                  <div style={{ width: 78, height: 30 }}><Sparkline data={spark} h={30} /></div>
                  <div style={{ textAlign: 'right', minWidth: 76 }}>
                    <div style={{ fontSize: 16, fontWeight: 700, color: t.text }}>{D.money(nToday, { dp: 0 })}</div>
                    <div style={{ fontSize: 12, color: t.ter }}>today</div>
                  </div>
                  <Icon name="chevron" s={16} c={t.ter} />
                </div>
              </Card>
            );
          })}
        </div>

        {/* top apps */}
        <div style={{ height: 22 }} />
        <SectionTitle action="All apps" onAction={() => nav.setTab('analytics')}>Top apps · today</SectionTitle>
        <Card pad={0}>
          {D.appMetrics(acc.id, 'today').slice(0, 4).map((r, i) => (
            <div key={r.app.id} onClick={() => nav.push({ type: 'app', appId: r.app.id })} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderTop: i ? `1px solid ${t.hair}` : 'none', cursor: 'pointer' }}>
              <window.BK.AppIcon app={r.app} s={38} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 15.5, fontWeight: 600, color: t.text }}>{r.app.name}</div>
                <div style={{ fontSize: 12.5, color: t.ter, marginTop: 1 }}>{r.app.platform} · eCPM {D.money(r.ecpm)}</div>
              </div>
              <div style={{ fontSize: 15.5, fontWeight: 700, color: t.text, marginRight: 6 }}>{D.money(r.earnings, { dp: 0 })}</div>
              <Icon name="chevron" s={15} c={t.ter} />
            </div>
          ))}
        </Card>
      </div>
    );
  }
  function NetworkDetail({ nid }) {
    const t = window.useT();
    const nav = window.useNav();
    const acc = nav.accountObj;
    const net = D.NETWORKS[nid];
    const [period, setPeriod] = useState('today');
    const s = useMemo(() => D.series(acc.id, nid), [acc.id, nid]);
    const last7 = D.lastN(s, 7);
    const chartData = last7.map(d => ({ value: d.value, dim: d.partial }));
    const labels = last7.map(d => D.DOW[d.date.getDay()][0]);
    const days = [...s].reverse().slice(0, 14);
    // network share of account (stable, by last 7d) → scale account-wide metrics
    const factor = D.sumN(s, 7) / Math.max(1, D.sumN(D.accountSeries(acc.id), 7));
    const accTot = D.totals(D.appMetrics(acc.id, period));
    const tot = { earnings: accTot.earnings * factor, impressions: accTot.impressions * factor, clicks: accTot.clicks * factor, requests: accTot.requests * factor, matched: accTot.matched * factor, ecpm: accTot.ecpm, ctr: accTot.ctr, matchRate: accTot.matchRate };
    const delta = D.periodDelta(acc.id, period);
    const cmp = D.PERIODS.find(p => p.id === period).cmp;

    return (
      <div style={{ padding: '0 16px 24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
          <NetBadge net={net} s={44} />
          <div style={{ fontSize: 28, fontWeight: 800, color: t.text, letterSpacing: -0.6 }}>{net.name}</div>
        </div>

        <div style={{ marginBottom: 14 }}><window.BK.PillTabs options={D.PERIODS} value={period} onChange={setPeriod} /></div>

        <div style={{ marginBottom: 18 }}><window.BK.MetricList tot={tot} delta={delta} cmp={cmp} /></div>

        <Card style={{ marginBottom: 22 }}>
          <div style={{ fontSize: 12.5, fontWeight: 700, color: t.sec, letterSpacing: 0.5, marginBottom: 14 }}>LAST 7 DAYS</div>
          <BarChart data={chartData} labels={labels} h={140} />
        </Card>

        <SectionTitle>Daily</SectionTitle>
        <Card pad={0}>
          {days.map((d, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', padding: '14px 16px', borderTop: i ? `1px solid ${t.hair}` : 'none' }}>
              <div style={{ flex: 1, fontSize: 15.5, color: t.text, fontWeight: 500 }}>
                {D.fmtDate(d.date)}{d.partial && <span style={{ color: t.accent, fontWeight: 600, fontSize: 12, marginLeft: 8 }}>· live</span>}
              </div>
              <div style={{ fontSize: 15.5, fontWeight: 700, color: t.text, marginRight: 8 }}>{D.money(d.value)}</div>
              <Icon name="chevron" s={15} c={t.ter} />
            </div>
          ))}
        </Card>
      </div>
    );
  }

  // ───────────────────────────── Reports / breakdowns ─────────────────────────────
  function Reports() {
    const t = window.useT();
    const nav = window.useNav();
    const acc = nav.accountObj;
    const [mode, setMode] = useState('daily');
    const combined = useMemo(() => D.accountSeries(acc.id), [acc.id]);

    let rows, periodTotal, periodLabel;
    if (mode === 'daily') {
      rows = [...combined].reverse().slice(0, 30).map(d => ({
        label: D.fmtDate(d.date), value: d.value, partial: d.partial,
      }));
      periodTotal = D.sumN(combined, 30); periodLabel = 'Last 30 days';
    } else {
      const agg = D.aggregate(combined, mode);
      rows = agg.slice(0, mode === 'weekly' ? 16 : mode === 'monthly' ? 12 : 4);
      periodTotal = rows.reduce((a, b) => a + b.value, 0);
      periodLabel = mode === 'weekly' ? 'Last 16 weeks' : mode === 'monthly' ? 'Last 12 months' : 'All time';
    }
    const maxVal = Math.max(...rows.map(r => r.value), 1);

    return (
      <div style={{ padding: '0 16px 24px' }}>
        <div style={{ marginBottom: 16 }}>
          <Segmented
            value={mode}
            onChange={setMode}
            options={[
              { value: 'daily', label: 'Daily' },
              { value: 'weekly', label: 'Weekly' },
              { value: 'monthly', label: 'Monthly' },
              { value: 'yearly', label: 'Yearly' },
            ]}
          />
        </div>

        <Card style={{ marginBottom: 18, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div style={{ fontSize: 12.5, color: t.sec, fontWeight: 600 }}>{periodLabel}</div>
            <div style={{ fontSize: 28, fontWeight: 800, color: t.text, letterSpacing: -1, marginTop: 2 }}>{D.money(periodTotal, { dp: 0 })}</div>
          </div>
          <div style={{ width: 100, height: 40 }}>
            <Sparkline data={(mode === 'daily' ? D.lastN(combined, 30) : [...rows].reverse()).map(r => r.value)} h={40} />
          </div>
        </Card>

        <Card pad={0}>
          {rows.map((r, i) => (
            <div key={i} style={{ padding: '13px 16px', borderTop: i ? `1px solid ${t.hair}` : 'none' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
                <span style={{ fontSize: 15, color: t.text, fontWeight: 500 }}>
                  {r.label}{r.partial && <span style={{ color: t.accent, fontWeight: 600, fontSize: 12, marginLeft: 8 }}>· live</span>}
                </span>
                <span style={{ fontSize: 15, fontWeight: 700, color: t.text }}>{D.money(r.value, { dp: 0 })}</span>
              </div>
              <div style={{ height: 6, borderRadius: 4, background: t.card2, overflow: 'hidden' }}>
                <div style={{ height: '100%', width: (r.value / maxVal * 100) + '%', borderRadius: 4, background: `linear-gradient(90deg, ${t.grad[0]}, ${t.grad[1]})`, transition: 'width .6s cubic-bezier(.22,1,.36,1)' }} />
              </div>
            </div>
          ))}
        </Card>
      </div>
    );
  }

  window.Screens = Object.assign(window.Screens || {}, { Dashboard, NetworkDetail, Reports, OverviewTiles });
})();

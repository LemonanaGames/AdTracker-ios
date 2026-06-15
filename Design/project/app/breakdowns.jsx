// breakdowns.jsx — period tabs, metric list, breakdown sections, App detail
(function () {
  const { useState } = React;
  const D = window.AppData;
  const { Card, Delta } = window.UI;

  // app icon tile (color derived from app.hue)
  function AppIcon({ app, s = 42, r }) {
    const radius = r != null ? r : s * 0.26;
    const h = app.hue;
    return (
      <div style={{ width: s, height: s, borderRadius: radius, flexShrink: 0,
        background: `linear-gradient(150deg, oklch(0.7 0.17 ${h}), oklch(0.52 0.17 ${h}))`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontWeight: 800, fontSize: s * 0.46, color: '#fff', letterSpacing: -0.5,
        boxShadow: `0 4px 12px oklch(0.5 0.17 ${h} / 0.4)` }}>{app.name[0]}</div>
    );
  }
  function FlagTile({ flag, s = 38 }) {
    const t = window.useT();
    return <div style={{ width: s, height: s, borderRadius: 10, background: t.card2, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: s * 0.6, flexShrink: 0 }}>{flag}</div>;
  }
  function UnitTile({ s = 38 }) {
    const t = window.useT();
    return <div style={{ width: s, height: s, borderRadius: 10, background: t.accentSoft, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}><Icon name="layers" s={s * 0.5} c={t.accent} /></div>;
  }

  // horizontal scrollable period / pill tabs
  function PillTabs({ options, value, onChange, small }) {
    const t = window.useT();
    return (
      <div style={{ display: 'flex', gap: 8, overflowX: 'auto', paddingBottom: 2, margin: small ? 0 : '0 -2px' }}>
        {options.map(o => {
          const sel = o.id === value;
          return (
            <button key={o.id} onClick={() => onChange(o.id)} style={{
              flexShrink: 0, border: 'none', cursor: 'pointer', borderRadius: 999,
              padding: small ? '6px 13px' : '8px 16px', fontFamily: 'inherit',
              fontSize: small ? 13 : 14.5, fontWeight: 600,
              background: sel ? t.text : t.card, color: sel ? t.bg : t.sec,
              transition: 'all .15s', whiteSpace: 'nowrap',
            }}>{o.label}</button>
          );
        })}
      </div>
    );
  }

  // full metric list (headline earnings + rows) — `tot` is a totals-like object
  function MetricList({ tot, delta, cmp }) {
    const t = window.useT();
    const rows = D.METRICS.filter(m => m.id !== 'earnings');
    return (
      <Card pad={0}>
        <div style={{ padding: '16px 16px 14px', display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
          <span style={{ fontSize: 26, fontWeight: 800, color: t.text, letterSpacing: -0.8 }}>{D.money(tot.earnings)}</span>
          {delta != null && <Delta v={delta} />}
          {cmp && <span style={{ fontSize: 12.5, color: t.ter }}>vs {cmp}</span>}
        </div>
        {rows.map((m, i) => (
          <div key={m.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderTop: `1px solid ${t.hair}` }}>
            <Icon name={m.icon} s={19} c={t.sec} />
            <span style={{ flex: 1, fontSize: 15.5, color: t.text }}>{m.label}</span>
            <span style={{ fontSize: 15.5, fontWeight: 700, color: t.text }}>{D.fmtMetric(m.id, tot[m.id])}</span>
          </div>
        ))}
      </Card>
    );
  }

  // breakdown section: title + metric tabs + ranked rows with share bars
  function Breakdown({ title, icon, items, metricOptions, onRow }) {
    const t = window.useT();
    const [metric, setMetric] = useState(metricOptions[0].id);
    const sorted = [...items].sort((a, b) => b.m[metric] - a.m[metric]);
    const max = Math.max(...sorted.map(r => r.m[metric]), 1);
    return (
      <div style={{ marginBottom: 22 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, margin: '0 4px 10px' }}>
          <Icon name={icon} s={20} c={t.text} />
          <span style={{ fontSize: 20, fontWeight: 700, color: t.text, letterSpacing: -0.4 }}>{title}</span>
        </div>
        <div style={{ marginBottom: 10 }}>
          <PillTabs small options={metricOptions} value={metric} onChange={setMetric} />
        </div>
        <Card pad={0}>
          {sorted.map((r, i) => (
            <div key={r.id} onClick={onRow ? () => onRow(r) : undefined} style={{ padding: '12px 16px', borderTop: i ? `1px solid ${t.hair}` : 'none', cursor: onRow ? 'pointer' : 'default' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                {r.lead}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 15.5, fontWeight: 600, color: t.text, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.name}</div>
                  {r.sub && <div style={{ fontSize: 12.5, color: t.ter, marginTop: 1 }}>{r.sub}</div>}
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontSize: 15.5, fontWeight: 700, color: t.text }}>{D.fmtMetric(metric, r.m[metric])}</div>
                  <div style={{ fontSize: 11.5, color: t.ter }}>{(r.m[metric] / max * 100).toFixed(0)}%</div>
                </div>
                {onRow && <Icon name="chevron" s={15} c={t.ter} />}
              </div>
              <div style={{ height: 4, borderRadius: 3, background: t.card2, marginTop: 9, overflow: 'hidden' }}>
                <div style={{ height: '100%', width: (r.m[metric] / max * 100) + '%', borderRadius: 3, background: `linear-gradient(90deg, ${t.grad[0]}, ${t.grad[1]})` }} />
              </div>
            </div>
          ))}
        </Card>
      </div>
    );
  }

  // build {m:{...}} item for a metrics row object
  function toM(o) { return { earnings: o.earnings, clicks: o.clicks, impressions: o.impressions, requests: o.requests, ecpm: o.ecpm, matchRate: o.matchRate, ctr: o.ctr, matched: o.matched }; }

  // ── App detail (push) ──
  function AppDetail({ appId, accId }) {
    const t = window.useT();
    const nav = window.useNav();
    const [period, setPeriod] = useState('today');
    const app = D.APPS.find(a => a.id === appId);
    // this app's row for the period
    const rows = D.appMetrics(accId, period);
    const row = rows.find(r => r.app.id === appId) || rows[0];
    const tot = { earnings: row.earnings, impressions: row.impressions, clicks: row.clicks, requests: row.requests, matched: row.matched, ecpm: row.ecpm, ctr: row.ctr, matchRate: row.matchRate };
    const delta = D.periodDelta(accId, period) * (0.6 + (app.hue % 50) / 100);
    const cmp = D.PERIODS.find(p => p.id === period).cmp;
    // ad units for this app
    const units = D.splitBy(tot, D.ADUNITS).map(u => ({ id: u.item.id, lead: <UnitTile />, name: u.item.name, sub: app.name, m: toM(u) }));

    return (
      <div style={{ padding: '0 16px 24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 13, marginBottom: 16 }}>
          <AppIcon app={app} s={52} />
          <div>
            <div style={{ fontSize: 26, fontWeight: 800, color: t.text, letterSpacing: -0.6 }}>{app.name}</div>
            <div style={{ fontSize: 13.5, color: t.sec }}>{app.platform} · com.demo.{app.id}</div>
          </div>
        </div>
        <div style={{ marginBottom: 14 }}><PillTabs options={D.PERIODS} value={period} onChange={setPeriod} /></div>
        <div style={{ marginBottom: 22 }}><MetricList tot={tot} delta={delta} cmp={cmp} /></div>
        <Breakdown title="Ad Units" icon="layers" items={units}
          metricOptions={[{ id: 'earnings', label: 'Earnings' }, { id: 'impressions', label: 'Impr.' }, { id: 'clicks', label: 'Clicks' }, { id: 'ecpm', label: 'eCPM' }]} />
      </div>
    );
  }

  window.BK = { AppIcon, FlagTile, UnitTile, PillTabs, MetricList, Breakdown, AppDetail, toM };
})();

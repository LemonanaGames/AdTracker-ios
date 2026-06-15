// widgets-watch.jsx — Home/Lock widgets + Apple Watch. Exposes window.Devices
(function () {
  const D = window.AppData;
  const { Sparkline, BarChart, Ring } = window.UI;

  function dataFor(accId) {
    const cmb = D.accountSeries(accId);
    const tot = D.totals(D.appMetrics(accId, 'today'));
    return {
      today: D.valueToday(cmb),
      last7: D.lastN(cmb, 7).map(d => ({ value: d.value, dim: d.partial })),
      last7vals: D.lastN(cmb, 7).map(d => d.value),
      d7: D.sumN(cmb, 7),
      yest: cmb[cmb.length - 2].value,
      goalPct: D.valueToday(cmb) / D.GOALS.daily,
      ecpm: tot.ecpm,
      impressions: tot.impressions,
      topApps: D.appMetrics(accId, 'today').slice(0, 3),
      acc: D.ACCOUNTS.find(a => a.id === accId),
    };
  }
  function delta(today, yest) { return (today / D.NOW_FRACTION - yest) / yest * 100; }

  // surface tokens for a widget given the theme (always slightly elevated)
  function surf(t) {
    return t.dark
      ? { bg: '#1c1c1e', text: '#fff', sec: 'rgba(235,235,245,0.6)' }
      : { bg: '#ffffff', text: '#16161a', sec: 'rgba(60,60,67,0.6)' };
  }

  // ── small home widget (158×158) ──
  function HomeSmall({ t, accId, label = true }) {
    const d = dataFor(accId); const s = surf(t);
    return (
      <div>
        <div style={{ width: 158, height: 158, borderRadius: 30, background: s.bg, padding: 16, boxSizing: 'border-box', display: 'flex', flexDirection: 'column', overflow: 'hidden', boxShadow: '0 10px 30px rgba(0,0,0,0.35)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <div style={{ width: 16, height: 16, borderRadius: 5, background: t.accent }} />
            <span style={{ fontSize: 11, fontWeight: 700, color: s.sec, letterSpacing: 0.3 }}>TODAY</span>
          </div>
          <div style={{ fontSize: 27, fontWeight: 800, color: s.text, letterSpacing: -1, marginTop: 10 }}>{D.money(d.today, { dp: 0 })}</div>
          <div style={{ fontSize: 12, color: t.pos, fontWeight: 700, marginTop: 1 }}>▲ {Math.abs(delta(d.today, d.yest)).toFixed(0)}% pace</div>
          <div style={{ flex: 1 }} />
          <div style={{ height: 36 }}><BarChartMini t={t} data={d.last7} /></div>
        </div>
        {label && <div style={{ textAlign: 'center', fontSize: 13, color: 'rgba(255,255,255,0.9)', marginTop: 8, fontWeight: 500 }}>Ad Report</div>}
      </div>
    );
  }

  // ── medium home widget (338×158) ──
  function HomeMedium({ t, accId, label = true }) {
    const d = dataFor(accId); const s = surf(t);
    return (
      <div>
        <div style={{ width: 338, height: 158, borderRadius: 30, background: s.bg, padding: 18, boxSizing: 'border-box', display: 'flex', gap: 18, overflow: 'hidden', boxShadow: '0 10px 30px rgba(0,0,0,0.35)' }}>
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <div style={{ width: 16, height: 16, borderRadius: 5, background: t.accent }} />
              <span style={{ fontSize: 11, fontWeight: 700, color: s.sec, letterSpacing: 0.3 }}>TODAY</span>
            </div>
            <div style={{ fontSize: 30, fontWeight: 800, color: s.text, letterSpacing: -1, marginTop: 8 }}>{D.money(d.today, { dp: 0 })}</div>
            <div style={{ fontSize: 12.5, color: t.pos, fontWeight: 700, marginTop: 2 }}>▲ {Math.abs(delta(d.today, d.yest)).toFixed(0)}% vs avg</div>
            <div style={{ flex: 1 }} />
            <div style={{ fontSize: 11.5, color: s.sec }}>{Math.round(d.goalPct * 100)}% of daily goal</div>
            <div style={{ height: 5, borderRadius: 3, background: t.dark ? '#39393d' : '#e7e7ec', marginTop: 5, overflow: 'hidden' }}>
              <div style={{ height: '100%', width: Math.min(100, d.goalPct * 100) + '%', background: t.accent, borderRadius: 3 }} />
            </div>
          </div>
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ fontSize: 11, fontWeight: 700, color: s.sec }}>LAST 7 DAYS</span>
              <span style={{ fontSize: 11, fontWeight: 700, color: s.text }}>{D.moneyK(d.d7)}</span>
            </div>
            <div style={{ height: 88, marginTop: 8 }}><BarChartMini t={t} data={d.last7} full /></div>
          </div>
        </div>
        {label && <div style={{ textAlign: 'center', fontSize: 13, color: 'rgba(255,255,255,0.9)', marginTop: 8, fontWeight: 500 }}>Ad Report</div>}
      </div>
    );
  }

  // ── top-apps home widget (338×158) ──
  function HomeApps({ t, accId, label = true }) {
    const d = dataFor(accId); const s = surf(t);
    return (
      <div>
        <div style={{ width: 338, height: 158, borderRadius: 30, background: s.bg, padding: '16px 18px', boxSizing: 'border-box', display: 'flex', flexDirection: 'column', overflow: 'hidden', boxShadow: '0 10px 30px rgba(0,0,0,0.35)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <div style={{ width: 14, height: 14, borderRadius: 4, background: t.accent }} />
              <span style={{ fontSize: 11, fontWeight: 700, color: s.sec, letterSpacing: 0.3 }}>TOP APPS · TODAY</span>
            </div>
            <span style={{ fontSize: 11, fontWeight: 700, color: s.text }}>{D.money(d.today, { dp: 0 })}</span>
          </div>
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
            {d.topApps.map((r, i) => (
              <div key={r.app.id} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                {window.BK
                  ? <window.BK.AppIcon app={r.app} s={26} r={7} />
                  : <div style={{ width: 26, height: 26, borderRadius: 7, background: t.accent }} />}
                <span style={{ flex: 1, fontSize: 14, fontWeight: 600, color: s.text, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.app.name}</span>
                <span style={{ fontSize: 13.5, color: s.sec, marginRight: 8 }}>{D.money(r.ecpm)}</span>
                <span style={{ fontSize: 14, fontWeight: 700, color: s.text, minWidth: 56, textAlign: 'right' }}>{D.money(r.earnings, { dp: 0 })}</span>
              </div>
            ))}
          </div>
        </div>
        {label && <div style={{ textAlign: 'center', fontSize: 13, color: 'rgba(255,255,255,0.9)', marginTop: 8, fontWeight: 500 }}>Ad Report</div>}
      </div>
    );
  }

  // mini bar chart (no deps on theme ctx)
  function BarChartMini({ t, data, full }) {
    const max = Math.max(...data.map(d => d.value), 1);
    return (
      <svg viewBox={`0 0 ${data.length * 10} 100`} preserveAspectRatio="none" style={{ width: '100%', height: '100%', display: 'block' }}>
        {data.map((d, i) => {
          const bw = 6.4, x = i * 10 + (10 - bw) / 2;
          const bh = Math.max(3, d.value / max * 96);
          return <rect key={i} x={x} y={100 - bh} width={bw} height={bh} rx={2.4} fill={d.dim ? (t.dark ? '#39393d' : '#dcdce2') : t.accent} />;
        })}
      </svg>
    );
  }

  // ── lock screen widgets ──
  function LockRect({ t, accId }) {
    const d = dataFor(accId);
    return (
      <div style={{ width: 320, height: 72, borderRadius: 16, background: 'rgba(255,255,255,0.14)', backdropFilter: 'blur(14px)', WebkitBackdropFilter: 'blur(14px)', padding: '10px 14px', boxSizing: 'border-box', display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{ width: 44, height: 44 }}>
          <Ring value={d.today} goal={D.GOALS.daily} size={44} sw={5} color="#fff" track="rgba(255,255,255,0.25)">
            <span style={{ fontSize: 11, fontWeight: 800, color: '#fff' }}>{Math.round(d.goalPct * 100)}</span>
          </Ring>
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.7)', fontWeight: 600 }}>TODAY · AD REPORT</div>
          <div style={{ fontSize: 22, fontWeight: 800, color: '#fff', letterSpacing: -0.5 }}>{D.money(d.today, { dp: 0 })}</div>
        </div>
        <div style={{ fontSize: 13, color: '#7be0a3', fontWeight: 700 }}>▲{Math.abs(delta(d.today, d.yest)).toFixed(0)}%</div>
      </div>
    );
  }
  function LockCircle({ t, accId }) {
    const d = dataFor(accId);
    return (
      <div style={{ textAlign: 'center' }}>
        <div style={{ width: 62, height: 62, position: 'relative' }}>
          <Ring value={d.today} goal={D.GOALS.daily} size={62} sw={6} color="#fff" track="rgba(255,255,255,0.25)">
            <span style={{ fontSize: 13, fontWeight: 800, color: '#fff', lineHeight: 1 }}>{D.moneyK(d.today).replace('$', '$')}</span>
          </Ring>
        </div>
      </div>
    );
  }

  // ── Apple Watch ──
  function WatchBezel({ children, w = 184, h = 224 }) {
    return (
      <div style={{ width: w + 16, height: h + 16, borderRadius: 52, background: '#0a0a0a', padding: 8, boxSizing: 'border-box', boxShadow: '0 18px 40px rgba(0,0,0,0.45), inset 0 0 0 2px #2a2a2a' }}>
        <div style={{ width: w, height: h, borderRadius: 44, background: '#000', overflow: 'hidden', position: 'relative' }}>{children}</div>
      </div>
    );
  }

  // watch app — main glance
  function WatchApp({ t, accId }) {
    const d = dataFor(accId);
    return (
      <WatchBezel>
        <div style={{ padding: '14px 16px', height: '100%', boxSizing: 'border-box', display: 'flex', flexDirection: 'column', color: '#fff' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 12, color: '#fff', fontWeight: 600 }}>
            <span style={{ color: t.accent }}>Ad Report</span>
            <span>9:41</span>
          </div>
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Ring value={d.today} goal={D.GOALS.daily} size={120} sw={11} color={t.accent} track="#1c1c1e">
              <div style={{ fontSize: 10, fontWeight: 700, color: 'rgba(255,255,255,0.6)' }}>TODAY</div>
              <div style={{ fontSize: 23, fontWeight: 800, color: '#fff', letterSpacing: -0.8 }}>{D.money(d.today, { dp: 0 })}</div>
              <div style={{ fontSize: 11, color: t.pos, fontWeight: 700 }}>▲{Math.abs(delta(d.today, d.yest)).toFixed(0)}%</div>
            </Ring>
          </div>
          <div style={{ display: 'flex', gap: 7 }}>
            <div style={{ flex: 1, background: '#1c1c1e', borderRadius: 11, padding: '7px 0', textAlign: 'center' }}>
              <div style={{ fontSize: 9, color: 'rgba(255,255,255,0.5)', fontWeight: 600 }}>7D</div>
              <div style={{ fontSize: 12.5, fontWeight: 700 }}>{D.moneyK(d.d7)}</div>
            </div>
            <div style={{ flex: 1, background: '#1c1c1e', borderRadius: 11, padding: '7px 0', textAlign: 'center' }}>
              <div style={{ fontSize: 9, color: 'rgba(255,255,255,0.5)', fontWeight: 600 }}>eCPM</div>
              <div style={{ fontSize: 12.5, fontWeight: 700 }}>{D.money(d.ecpm)}</div>
            </div>
            <div style={{ flex: 1, background: '#1c1c1e', borderRadius: 11, padding: '7px 0', textAlign: 'center' }}>
              <div style={{ fontSize: 9, color: 'rgba(255,255,255,0.5)', fontWeight: 600 }}>GOAL</div>
              <div style={{ fontSize: 12.5, fontWeight: 700, color: t.accent }}>{Math.round(d.goalPct * 100)}%</div>
            </div>
          </div>
        </div>
      </WatchBezel>
    );
  }

  // watch face with complications
  function WatchFace({ t, accId }) {
    const d = dataFor(accId);
    return (
      <WatchBezel>
        <div style={{ height: '100%', padding: 14, boxSizing: 'border-box', display: 'flex', flexDirection: 'column', color: '#fff', background: 'radial-gradient(120% 80% at 50% 0%, #14202b, #000)' }}>
          {/* top corner complications */}
          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, fontWeight: 700 }}>
            <span style={{ color: t.accent }}>◷ {D.money(d.today, { dp: 0 })}</span>
            <span style={{ color: 'rgba(255,255,255,0.6)' }}>84%</span>
          </div>
          {/* time */}
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'flex-end' }}>
            <div style={{ fontSize: 50, fontWeight: 300, letterSpacing: -1, color: t.accent }}>9:41</div>
          </div>
          {/* bottom rectangular complication */}
          <div style={{ background: 'rgba(255,255,255,0.08)', borderRadius: 12, padding: '8px 10px', display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ width: 28, height: 28 }}>
              <Ring value={d.today} goal={D.GOALS.daily} size={28} sw={4} color={t.accent} track="rgba(255,255,255,0.2)" />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 9, color: 'rgba(255,255,255,0.55)', fontWeight: 600 }}>TODAY · {Math.round(d.goalPct * 100)}% OF GOAL</div>
              <div style={{ fontSize: 14, fontWeight: 800 }}>{D.money(d.today, { dp: 0 })}</div>
            </div>
          </div>
        </div>
      </WatchBezel>
    );
  }

  window.Devices = { HomeSmall, HomeMedium, HomeApps, LockRect, LockCircle, WatchApp, WatchFace, dataFor };
})();

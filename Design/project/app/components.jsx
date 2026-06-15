// components.jsx — shared UI primitives. Exposes window.UI and window.ThemeCtx
(function () {
  const { createContext, useContext } = React;
  const ThemeCtx = createContext(null);
  const useT = () => useContext(ThemeCtx);

  // ---- network monogram tile (generic, not a brand logo) ------------------
  function NetBadge({ net, s = 38, r }) {
    const radius = r != null ? r : s * 0.28;
    const grad = net.id === 'applovin'
      ? ['#8b6df7', '#5b6df5']
      : ['#4aa863', '#2e8b48'];
    const letter = net.id === 'applovin' ? 'A' : 'G';
    return (
      <div style={{
        width: s, height: s, borderRadius: radius, flexShrink: 0,
        background: `linear-gradient(150deg, ${grad[0]}, ${grad[1]})`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontWeight: 800, fontSize: s * 0.5, color: '#fff',
        fontFamily: '-apple-system, system-ui', letterSpacing: -0.5,
        boxShadow: `0 4px 12px ${grad[1]}44`,
      }}>{letter}</div>
    );
  }

  // ---- card ---------------------------------------------------------------
  function Card({ children, style, pad = 16, onClick, className }) {
    const t = useT();
    return (
      <div onClick={onClick} className={className} style={{
        background: t.card, borderRadius: 22, padding: pad,
        boxShadow: t.dark ? 'none' : '0 1px 2px rgba(0,0,0,0.04)',
        ...style,
      }}>{children}</div>
    );
  }

  // ---- bar chart ----------------------------------------------------------
  function BarChart({ data, h = 150, active = true, gap = 0.36, labels }) {
    const t = useT();
    const max = Math.max(...data.map(d => d.value), 1);
    const n = data.length;
    const gradId = 'bg' + Math.random().toString(36).slice(2, 7);
    return (
      <div style={{ width: '100%' }}>
        <svg viewBox={`0 0 ${n * 10} 100`} preserveAspectRatio="none" style={{ width: '100%', height: h, display: 'block', overflow: 'visible' }}>
          <defs>
            <linearGradient id={gradId} x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={t.grad[0]} />
              <stop offset="100%" stopColor={t.grad[1]} />
            </linearGradient>
          </defs>
          {data.map((d, i) => {
            const bw = 10 * (1 - gap);
            const x = i * 10 + (10 - bw) / 2;
            const bh = active ? Math.max(2.5, (d.value / max) * 92) : 0;
            return (
              <rect key={i} x={x} y={100 - bh} width={bw} height={bh} rx={bw * 0.32}
                fill={d.dim ? t.card2 : `url(#${gradId})`}
                style={{ transition: `y .6s cubic-bezier(.22,1,.36,1) ${i * 0.03}s, height .6s cubic-bezier(.22,1,.36,1) ${i * 0.03}s` }} />
            );
          })}
        </svg>
        {labels && (
          <div style={{ display: 'flex', marginTop: 8 }}>
            {data.map((d, i) => (
              <div key={i} style={{ flex: 1, textAlign: 'center', fontSize: 11, color: t.ter, fontWeight: 600 }}>{labels[i]}</div>
            ))}
          </div>
        )}
      </div>
    );
  }

  // ---- sparkline ----------------------------------------------------------
  function Sparkline({ data, w = 100, h = 32, fill = true, sw = 2 }) {
    const t = useT();
    const max = Math.max(...data, 1), min = Math.min(...data);
    const rng = max - min || 1;
    const pts = data.map((v, i) => [i / (data.length - 1) * w, h - ((v - min) / rng) * (h - 4) - 2]);
    const d = pts.map((p, i) => (i ? 'L' : 'M') + p[0].toFixed(1) + ' ' + p[1].toFixed(1)).join(' ');
    const area = d + ` L ${w} ${h} L 0 ${h} Z`;
    const gradId = 'sp' + Math.random().toString(36).slice(2, 7);
    return (
      <svg viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none" style={{ width: '100%', height: h, display: 'block', overflow: 'visible' }}>
        <defs>
          <linearGradient id={gradId} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={t.accent} stopOpacity="0.28" />
            <stop offset="100%" stopColor={t.accent} stopOpacity="0" />
          </linearGradient>
        </defs>
        {fill && <path d={area} fill={`url(#${gradId})`} />}
        <path d={d} fill="none" stroke={t.accent} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    );
  }

  // ---- progress ring ------------------------------------------------------
  function Ring({ value, goal, size = 160, sw = 14, children, color, track }) {
    const t = useT();
    const pct = Math.max(0, Math.min(1, value / goal));
    const r = (size - sw) / 2;
    const c = 2 * Math.PI * r;
    const col = color || t.accent;
    return (
      <div style={{ position: 'relative', width: size, height: size }}>
        <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
          <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={track || t.card2} strokeWidth={sw} />
          <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={col} strokeWidth={sw}
            strokeLinecap="round" strokeDasharray={c} strokeDashoffset={c * (1 - pct)}
            style={{ transition: 'stroke-dashoffset 1s cubic-bezier(.22,1,.36,1)' }} />
        </svg>
        <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
          {children}
        </div>
      </div>
    );
  }

  // ---- segmented control --------------------------------------------------
  function Segmented({ options, value, onChange, small }) {
    const t = useT();
    return (
      <div style={{
        display: 'flex', background: t.card2, borderRadius: 12, padding: 3, gap: 2,
      }}>
        {options.map(o => {
          const sel = o.value === value;
          return (
            <button key={o.value} onClick={() => onChange(o.value)} style={{
              flex: 1, border: 'none', cursor: 'pointer', borderRadius: 9,
              padding: small ? '6px 4px' : '8px 4px',
              fontSize: small ? 12.5 : 14, fontWeight: 600,
              fontFamily: '-apple-system, system-ui',
              background: sel ? (t.dark ? t.card : '#fff') : 'transparent',
              color: sel ? t.text : t.sec,
              boxShadow: sel ? '0 1px 3px rgba(0,0,0,0.12)' : 'none',
              transition: 'all .18s',
            }}>{o.label}</button>
          );
        })}
      </div>
    );
  }

  // ---- delta chip ---------------------------------------------------------
  function Delta({ v, sub }) {
    const t = useT();
    const up = v >= 0;
    const col = up ? t.pos : t.neg;
    return (
      <span style={{
        display: 'inline-flex', alignItems: 'center', gap: 3,
        color: col, fontWeight: 700, fontSize: 13,
        background: up ? (t.dark ? 'rgba(76,195,138,0.13)' : 'rgba(31,157,87,0.1)') : 'rgba(255,107,107,0.13)',
        padding: '3px 8px', borderRadius: 8,
      }}>
        <Icon name={up ? 'arrowUp' : 'arrowDown'} s={12} c={col} sw={3} />
        {window.AppData.pct(Math.abs(v) * (up ? 1 : -1)).replace('-', '')}
        {sub && <span style={{ color: t.ter, fontWeight: 500, marginLeft: 2 }}>{sub}</span>}
      </span>
    );
  }

  // ---- section header -----------------------------------------------------
  function SectionTitle({ children, action, onAction }) {
    const t = useT();
    return (
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', margin: '0 4px 10px' }}>
        <div style={{ fontSize: 20, fontWeight: 700, color: t.text, letterSpacing: -0.4 }}>{children}</div>
        {action && <button onClick={onAction} style={{ border: 'none', background: 'none', color: t.accent, fontWeight: 600, fontSize: 15, cursor: 'pointer', fontFamily: 'inherit' }}>{action}</button>}
      </div>
    );
  }

  window.ThemeCtx = ThemeCtx;
  window.useT = useT;
  window.UI = { NetBadge, Card, BarChart, Sparkline, Ring, Segmented, Delta, SectionTitle };
})();

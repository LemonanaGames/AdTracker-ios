// main.jsx — navigation shell, tab bar, overlays, device showcase, tweaks
(function () {
  const { useState, useEffect, useRef, createContext, useContext } = React;
  const D = window.AppData;
  const S = window.Screens;
  const Dev = window.Devices;
  const { getTheme } = window.Theme;

  const NavCtx = createContext(null);
  window.useNav = () => useContext(NavCtx);

  // which presentation style a pushed screen uses
  const SHEETS = { accounts: 1, editGoal: 1, timePicker: 1, paywall: 1, configure: 1 };
  const FULL = { notifPreview: 1 };
  function presOf(type) { return SHEETS[type] ? 'sheet' : FULL[type] ? 'full' : 'push'; }

  // ── animated overlay wrapper ──
  function Overlay({ presentation, closing, onExited, onBackdrop, children, t }) {
    const [shown, setShown] = useState(false);
    useEffect(() => { const r = requestAnimationFrame(() => setShown(true)); return () => cancelAnimationFrame(r); }, []);
    useEffect(() => {
      if (closing) { setShown(false); const tm = setTimeout(onExited, 340); return () => clearTimeout(tm); }
    }, [closing]);

    const sheet = presentation === 'sheet';
    const transform = sheet || presentation === 'full'
      ? (shown ? 'translateY(0)' : 'translateY(100%)')
      : (shown ? 'translateX(0)' : 'translateX(100%)');

    return (
      <>
        {sheet && <div onClick={onBackdrop} style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', opacity: shown ? 1 : 0, transition: 'opacity .34s', zIndex: 30 }} />}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0,
          top: sheet ? 48 : 0,
          background: t.bg,
          borderTopLeftRadius: sheet ? 38 : 0, borderTopRightRadius: sheet ? 38 : 0,
          overflow: 'hidden', zIndex: 31,
          transform, transition: 'transform .36s cubic-bezier(.32,.72,0,1)',
          boxShadow: sheet ? '0 -10px 40px rgba(0,0,0,0.4)' : 'none',
          display: 'flex', flexDirection: 'column',
        }}>{children}</div>
      </>
    );
  }

  // ── screen scaffold (header chrome + scroll) ──
  function Scaffold({ presentation, title, onBack, onClose, trailing, children, noScroll }) {
    const t = window.useT();
    const sheet = presentation === 'sheet';
    const push = presentation === 'push';
    const tab = presentation === 'tab' || !presentation;

    const header = (
      <>
        {sheet && (
          <div style={{ display: 'flex', alignItems: 'center', padding: '14px 16px 6px', position: 'relative' }}>
            <div style={{ position: 'absolute', top: 8, left: '50%', transform: 'translateX(-50%)', width: 36, height: 5, borderRadius: 3, background: t.ter, opacity: 0.5 }} />
            <div style={{ flex: 1, fontSize: 20, fontWeight: 700, color: t.text, paddingTop: 8 }}>{title}</div>
            <button onClick={onClose} style={{ width: 30, height: 30, borderRadius: 999, border: 'none', cursor: 'pointer', background: t.card2, display: 'flex', alignItems: 'center', justifyContent: 'center', marginTop: 8 }}>
              <Icon name="x" s={16} c={t.sec} sw={2.5} />
            </button>
          </div>
        )}
        {push && (
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 12px', height: 44 }}>
            <button onClick={onBack} style={{ width: 38, height: 38, borderRadius: 999, border: 'none', cursor: 'pointer', background: t.card, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon name="chevronL" s={20} c={t.accent} />
            </button>
            {trailing || <div />}
          </div>
        )}
        {push && title && <div style={{ fontSize: 32, fontWeight: 800, color: t.text, letterSpacing: -0.6, padding: '4px 16px 12px' }}>{title}</div>}
        {tab && (
          <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', padding: '0 16px 8px' }}>
            <div style={{ fontSize: 32, fontWeight: 800, color: t.text, letterSpacing: -0.6 }}>{title}</div>
            {trailing}
          </div>
        )}
      </>
    );

    return (
      <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
        <div style={{ height: tab || push ? 52 : 0, flexShrink: 0 }} />
        {header}
        <div style={{ flex: 1, overflowY: noScroll ? 'hidden' : 'auto', WebkitOverflowScrolling: 'touch' }}>
          <div style={{ paddingBottom: tab ? 104 : 24 }}>{children}</div>
        </div>
      </div>
    );
  }

  // ── device info (in-app preview of widgets / watch) ──
  function DeviceInfo({ kind }) {
    const t = window.useT();
    const nav = window.useNav();
    const wall = 'linear-gradient(160deg, #2a3340, #11151b 70%)';
    if (kind === 'watch') {
      return (
        <div style={{ padding: '0 16px 24px' }}>
          <div style={{ fontSize: 14, color: t.sec, margin: '0 4px 18px', lineHeight: 1.4 }}>Glance at today's revenue from your wrist, or add a complication to any watch face.</div>
          <div style={{ borderRadius: 26, background: wall, padding: 24, display: 'flex', justifyContent: 'center', gap: 18, flexWrap: 'wrap', marginBottom: 14 }}>
            <Dev.WatchApp t={t} accId={nav.account} />
            <Dev.WatchFace t={t} accId={nav.account} />
          </div>
          <div style={{ display: 'flex', justifyContent: 'center', gap: 60, fontSize: 12.5, color: t.ter, fontWeight: 500 }}><span>Watch app</span><span>Face complication</span></div>
        </div>
      );
    }
    return (
      <div style={{ padding: '0 16px 24px' }}>
        <div style={{ fontSize: 14, color: t.sec, margin: '0 4px 18px', lineHeight: 1.4 }}>Add a widget to your Home or Lock Screen to keep revenue in sight all day.</div>
        <div style={{ borderRadius: 26, background: wall, padding: '26px 20px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22, marginBottom: 10 }}>
          <div style={{ display: 'flex', gap: 16, alignItems: 'flex-start', flexWrap: 'wrap', justifyContent: 'center' }}>
            <Dev.HomeSmall t={t} accId={nav.account} />
            <Dev.HomeMedium t={t} accId={nav.account} />
            <Dev.HomeApps t={t} accId={nav.account} />
          </div>
          <div style={{ width: '100%', borderTop: '1px solid rgba(255,255,255,0.1)', paddingTop: 20, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
            <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.5)', fontWeight: 600, letterSpacing: 0.4 }}>LOCK SCREEN</span>
            <Dev.LockRect t={t} accId={nav.account} />
          </div>
        </div>
      </div>
    );
  }

  // ── tab bar ──
  function TabBar() {
    const t = window.useT();
    const nav = window.useNav();
    const tabs = [
      { id: 'home', icon: 'home', label: 'Home' },
      { id: 'reports', icon: 'chart', label: 'Reports' },
      { id: 'goals', icon: 'target', label: 'Goals' },
      { id: 'analytics', icon: 'pulse', label: 'Insights' },
      { id: 'settings', icon: 'gear', label: 'Settings' },
    ];
    return (
      <div style={{ position: 'absolute', left: 0, right: 0, bottom: 0, zIndex: 20, paddingBottom: 22, paddingTop: 8,
        background: t.dark ? 'rgba(10,10,12,0.78)' : 'rgba(244,244,246,0.82)',
        backdropFilter: 'blur(20px) saturate(180%)', WebkitBackdropFilter: 'blur(20px) saturate(180%)',
        borderTop: `0.5px solid ${t.hair}`, display: 'flex' }}>
        {tabs.map(tb => {
          const on = nav.tab === tb.id && nav.stack.length === 0;
          return (
            <button key={tb.id} onClick={() => nav.setTab(tb.id)} style={{ flex: 1, border: 'none', background: 'none', cursor: 'pointer', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3, padding: '4px 0' }}>
              <Icon name={tb.icon} s={25} c={on ? t.tabActive : t.ter} sw={on ? 2.3 : 2} />
              <span style={{ fontSize: 10.5, fontWeight: on ? 700 : 500, color: on ? t.tabActive : t.ter }}>{tb.label}</span>
            </button>
          );
        })}
      </div>
    );
  }

  // ── the phone (interactive app) ──
  function Phone({ t, state, dispatch }) {
    const navValue = {
      ...state, ...dispatch,
      accountObj: D.ACCOUNTS.find(a => a.id === state.account),
    };
    const tabTitles = { home: null, reports: 'Reports', goals: 'Goals', analytics: 'Insights', settings: 'Settings' };
    const tabTrailing = {
      home: <button onClick={() => dispatch.push({ type: 'configure' })} style={iconPill(t)}><Icon name="plus" s={20} c={t.accent} /></button>,
      settings: null,
    };

    function renderTab() {
      switch (state.tab) {
        case 'home': return <Scaffold presentation="tab" trailing={null}><S.Dashboard /></Scaffold>;
        case 'reports': return <Scaffold presentation="tab" title="Reports"><S.Reports /></Scaffold>;
        case 'goals': return <Scaffold presentation="tab" title="Goals"><S.Goals /></Scaffold>;
        case 'analytics': return <Scaffold presentation="tab" title="Insights"><S.Analytics /></Scaffold>;
        case 'settings': return <Scaffold presentation="tab" title="Settings"><S.Settings /></Scaffold>;
        default: return null;
      }
    }

    function renderOverlayInner(item) {
      const { type } = item;
      const back = () => dispatch.pop();
      switch (type) {
        case 'network': return <Scaffold presentation="push" onBack={back} trailing={<button style={iconPill(t)} onClick={() => {}}><Icon name="share" s={18} c={t.accent} /></button>}><S.NetworkDetail nid={item.nid} /></Scaffold>;
        case 'app': return <Scaffold presentation="push" onBack={back} trailing={<button style={iconPill(t)} onClick={() => {}}><Icon name="share" s={18} c={t.accent} /></button>}><window.BK.AppDetail appId={item.appId} accId={state.account} /></Scaffold>;
        case 'notifications': return <Scaffold presentation="push" onBack={back} title="Notifications"><S.Notifications /></Scaffold>;
        case 'deviceInfo': return <Scaffold presentation="push" onBack={back} title={item.kind === 'watch' ? 'Apple Watch' : 'Widgets'}><DeviceInfo kind={item.kind} /></Scaffold>;
        case 'accounts': return <Scaffold presentation="sheet" title="Accounts" onClose={back}><S.Accounts /></Scaffold>;
        case 'editGoal': return <Scaffold presentation="sheet" title="Edit goal" onClose={back}><S.EditGoal period={item.period} /></Scaffold>;
        case 'timePicker': return <Scaffold presentation="sheet" title="Reminder time" onClose={back}><S.TimePicker /></Scaffold>;
        case 'configure': return <Scaffold presentation="sheet" title={item.adding ? 'New account' : 'Networks'} onClose={back}><S.Configure adding={item.adding} /></Scaffold>;
        case 'paywall': return <Scaffold presentation="sheet" title="" onClose={back}><S.Paywall /></Scaffold>;
        case 'notifPreview': return <S.NotifPreview />;
        default: return null;
      }
    }

    return (
      <NavCtx.Provider value={navValue}>
        <window.ThemeCtx.Provider value={t}>
          <IOSDevice dark={t.dark} width={390} height={844}>
            <div style={{ position: 'relative', height: '100%', background: t.bg, overflow: 'hidden' }}>
              {renderTab()}
              <TabBar />
              {state.stack.map((item) => (
                <Overlay key={item.id} presentation={presOf(item.type)} closing={item.closing} t={t}
                  onBackdrop={() => dispatch.pop()}
                  onExited={() => dispatch.removeOverlay(item.id)}>
                  {renderOverlayInner(item)}
                </Overlay>
              ))}
            </div>
          </IOSDevice>
        </window.ThemeCtx.Provider>
      </NavCtx.Provider>
    );
  }
  function iconPill(t) { return { width: 38, height: 38, borderRadius: 999, border: 'none', cursor: 'pointer', background: t.card, display: 'flex', alignItems: 'center', justifyContent: 'center' }; }

  // ── companion devices column ──
  function Companion({ t, accId }) {
    const cap = { fontSize: 12.5, color: '#8a8a90', fontWeight: 600, margin: '0 0 12px', letterSpacing: 0.3, textTransform: 'uppercase' };
    const wall = { borderRadius: 28, background: 'linear-gradient(165deg, #2b3440, #12161c 75%)', padding: 22, display: 'flex', justifyContent: 'center', gap: 18, flexWrap: 'wrap' };
    return (
      <div style={{ display: 'flex', flexDirection: 'column', gap: 30, width: 380 }}>
        <div>
          <div style={cap}>Apple Watch</div>
          <div style={wall}><Dev.WatchApp t={t} accId={accId} /><Dev.WatchFace t={t} accId={accId} /></div>
        </div>
        <div>
          <div style={cap}>Home Screen widgets</div>
          <div style={{ ...wall, flexDirection: 'column', alignItems: 'center', gap: 18 }}>
            <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', justifyContent: 'center' }}>
              <Dev.HomeSmall t={t} accId={accId} />
              <Dev.HomeMedium t={t} accId={accId} />
            </div>
            <Dev.HomeApps t={t} accId={accId} />
          </div>
        </div>
        <div>
          <div style={cap}>Lock Screen widget</div>
          <div style={{ ...wall, background: 'linear-gradient(165deg, #1d2733, #0b0f14 75%)', flexDirection: 'column', gap: 8 }}>
            <Dev.LockRect t={t} accId={accId} />
          </div>
        </div>
      </div>
    );
  }

  // ── root ──
  const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
    "direction": "midnight",
    "accent": "default",
    "pro": true,
    "showCompanion": true
  }/*EDITMODE-END*/;

  function App() {
    const [tw, setTweak] = window.useTweaks(TWEAK_DEFAULTS);
    const baseTheme = getTheme(tw.direction);
    // accent override
    const t = applyAccent(baseTheme, tw.accent);

    const [account, setAccount] = useState('main');
    const [tab, setTab] = useState('home');
    const [stack, setStack] = useState([]);
    const [isPro, setPro] = useState(true);
    const [prefs, setPrefs] = useState({ daily: true, dailyTime: '9:00 PM', sleep: true, away: true, goal: true, mover: false, milestone: 5000 });
    const idRef = useRef(1);

    useEffect(() => { setPro(!!tw.pro); }, [tw.pro]);

    const dispatch = {
      setAccount, setTab: (x) => { setStack([]); setTab(x); },
      push: (screen) => setStack(s => [...s, { ...screen, id: idRef.current++ }]),
      pop: () => setStack(s => s.length ? s.map((it, i) => i === s.length - 1 ? { ...it, closing: true } : it) : s),
      removeOverlay: (id) => setStack(s => s.filter(it => it.id !== id)),
      setPrefs, setPro: (v) => { setPro(v); setTweak('pro', v); },
      isPro, prefs,
      cycleTheme: () => { const order = ['midnight', 'graphite', 'mist']; setTweak('direction', order[(order.indexOf(tw.direction) + 1) % 3]); },
    };
    // expose theme cycle to settings appearance row
    dispatch.openTweaks = dispatch.cycleTheme;

    const state = { account, tab, stack, isPro, prefs };

    return (
      <div style={{ minHeight: '100vh', background: '#0e0f11', display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '34px 20px 60px', fontFamily: '-apple-system, system-ui, sans-serif' }}>
        <div style={{ textAlign: 'center', marginBottom: 28 }}>
          <div style={{ fontSize: 13, color: '#6f7075', fontWeight: 600, letterSpacing: 1, textTransform: 'uppercase' }}>Interactive prototype · {t.label}</div>
          <div style={{ fontSize: 26, color: '#f5f5f7', fontWeight: 800, marginTop: 4, letterSpacing: -0.5 }}>Ad Report — revenue tracker</div>
          <div style={{ fontSize: 13.5, color: '#8a8a90', marginTop: 6 }}>Tap around the phone. Switch visual direction & accent in <b style={{ color: '#bcbcc2' }}>Tweaks</b>.</div>
        </div>
        <div style={{ display: 'flex', gap: 54, alignItems: 'flex-start', justifyContent: 'center', flexWrap: 'wrap' }}>
          <Phone t={t} state={state} dispatch={dispatch} />
          {tw.showCompanion && (
            <window.ThemeCtx.Provider value={t}><Companion t={t} accId={account} /></window.ThemeCtx.Provider>
          )}
        </div>

        <window.TweaksPanel>
          <window.TweakSection label="Visual direction" />
          <window.TweakSelect label="Direction" value={tw.direction}
            options={[{ value: 'midnight', label: 'Midnight (teal)' }, { value: 'graphite', label: 'Graphite (mono)' }, { value: 'mist', label: 'Mist (light)' }]}
            onChange={v => setTweak('direction', v)} />
          <window.TweakColor label="Accent" value={tw.accent === 'default' ? baseTheme.accent : tw.accent}
            options={[baseTheme.accent, '#5cb7c9', '#7b5bf5', '#4cc38a', '#ff9f43', '#5b5bf0']}
            onChange={v => setTweak('accent', v)} />
          <window.TweakSection label="Content" />
          <window.TweakToggle label="Companion devices" value={tw.showCompanion} onChange={v => setTweak('showCompanion', v)} />
          <window.TweakToggle label="Reporting Pro unlocked" value={tw.pro} onChange={v => setTweak('pro', v)} />
        </window.TweaksPanel>
      </div>
    );
  }

  function applyAccent(theme, accent) {
    if (!accent || accent === 'default' || accent === theme.accent) return theme;
    return { ...theme, accent, grad: [accent, shade(accent, -0.18)], accentSoft: hexA(accent, theme.dark ? 0.16 : 0.1), tabActive: theme.tabActive === theme.accent ? accent : theme.tabActive };
  }
  function hexA(hex, a) { const c = hx(hex); return `rgba(${c[0]},${c[1]},${c[2]},${a})`; }
  function shade(hex, amt) { const c = hx(hex).map(v => Math.max(0, Math.min(255, Math.round(v + v * amt)))); return '#' + c.map(v => v.toString(16).padStart(2, '0')).join(''); }
  function hx(hex) { const h = hex.replace('#', ''); return [0, 2, 4].map(i => parseInt(h.slice(i, i + 2), 16)); }

  window.AdReportApp = App;
})();

// screens-settings.jsx — Settings, Notifications, Configure, Paywall, NotifPreview
(function () {
  const { useState } = React;
  const D = window.AppData;
  const { Card } = window.UI;
  const primaryBtn = (t) => ({ width: '100%', padding: '15px', borderRadius: 16, border: 'none', cursor: 'pointer', background: t.accent, color: t.accentText, fontSize: 17, fontWeight: 700, fontFamily: 'inherit' });

  // toggle switch
  function Toggle({ on, onChange }) {
    const t = window.useT();
    return (
      <button onClick={() => onChange(!on)} style={{
        width: 51, height: 31, borderRadius: 999, border: 'none', cursor: 'pointer', padding: 2,
        background: on ? t.pos : (t.dark ? '#39393d' : '#e3e3e8'), transition: 'background .2s', flexShrink: 0,
      }}>
        <div style={{ width: 27, height: 27, borderRadius: 999, background: '#fff', transform: on ? 'translateX(20px)' : 'translateX(0)', transition: 'transform .22s cubic-bezier(.4,1.3,.5,1)', boxShadow: '0 1px 3px rgba(0,0,0,0.25)' }} />
      </button>
    );
  }

  // a settings row
  function Row({ icon, iconBg, title, sub, detail, onClick, right, last }) {
    const t = window.useT();
    return (
      <div onClick={onClick} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', cursor: onClick ? 'pointer' : 'default', borderTop: last === 'first' ? 'none' : `1px solid ${t.hair}`, position: 'relative' }}>
        {icon && <div style={{ width: 30, height: 30, borderRadius: 8, background: iconBg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}><Icon name={icon} s={18} c="#fff" /></div>}
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 15.5, color: t.text, fontWeight: 500 }}>{title}</div>
          {sub && <div style={{ fontSize: 12.5, color: t.ter, marginTop: 1 }}>{sub}</div>}
        </div>
        {detail && <span style={{ fontSize: 14.5, color: t.sec }}>{detail}</span>}
        {right}
        {onClick && !right && <Icon name="chevron" s={15} c={t.ter} />}
      </div>
    );
  }
  function Group({ children, header }) {
    const t = window.useT();
    return (
      <div style={{ marginBottom: 20 }}>
        {header && <div style={{ fontSize: 13, color: t.sec, fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.3, margin: '0 20px 7px' }}>{header}</div>}
        <Card pad={0}>{children}</Card>
      </div>
    );
  }

  // ───────────────────────────── Settings ─────────────────────────────
  function Settings() {
    const t = window.useT();
    const nav = window.useNav();
    return (
      <div style={{ padding: '0 16px 24px' }}>
        {!nav.isPro && (
          <Card onClick={() => nav.push({ type: 'paywall' })} style={{ marginBottom: 20, cursor: 'pointer', background: `linear-gradient(125deg, ${t.grad[0]}, ${t.grad[1]})`, display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{ width: 44, height: 44, borderRadius: 12, background: 'rgba(255,255,255,0.22)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Icon name="sparkle" s={24} c="#fff" />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 17, fontWeight: 800, color: '#fff' }}>Reporting Pro</div>
              <div style={{ fontSize: 13, color: 'rgba(255,255,255,0.9)', marginTop: 1 }}>Widgets, Apple Watch & full history</div>
            </div>
            <Icon name="chevron" s={18} c="rgba(255,255,255,0.9)" />
          </Card>
        )}

        <Group header="Data">
          <Row last="first" icon="wallet" iconBg="#5b6df5" title="Accounts & Networks" sub={nav.accountObj.name} onClick={() => nav.push({ type: 'configure' })} />
          <Row icon="target" iconBg="#4cc38a" title="Goals" onClick={() => nav.setTab('goals')} />
        </Group>

        <Group header="Notifications & Devices">
          <Row last="first" icon="bell" iconBg="#ff6b6b" title="Notifications" sub={nav.prefs.daily ? 'Daily summary at ' + nav.prefs.dailyTime : 'Off'} onClick={() => nav.push({ type: 'notifications' })} />
          <Row icon="widget" iconBg="#ff9f43" title="Widgets" sub="Home & Lock Screen" onClick={() => nav.push({ type: 'deviceInfo', kind: 'widgets' })} />
          <Row icon="watch" iconBg="#111" title="Apple Watch" sub="Complications & app" onClick={() => nav.push({ type: 'deviceInfo', kind: 'watch' })} />
        </Group>

        <Group header="App">
          <Row last="first" icon="eye" iconBg="#8b6df7" title="Appearance" detail={t.label} onClick={() => nav.openTweaks && nav.openTweaks()} />
          <Row icon="dollar" iconBg="#34A853" title="Currency" detail="USD ($)" onClick={() => {}} />
          <Row icon="gear" iconBg="#8e8e93" title="About" detail="v2.0" onClick={() => {}} />
        </Group>
        <div style={{ textAlign: 'center', fontSize: 12.5, color: t.ter, marginTop: 8 }}>Ad Report · {nav.isPro ? 'Pro' : 'Free'}</div>
      </div>
    );
  }

  // ───────────────────────────── Notifications ─────────────────────────────
  function Notifications() {
    const t = window.useT();
    const nav = window.useNav();
    const p = nav.prefs;
    const set = (k, v) => nav.setPrefs({ ...p, [k]: v });
    return (
      <div style={{ padding: '0 16px 28px' }}>
        <div style={{ fontSize: 14, color: t.sec, margin: '4px 4px 16px', lineHeight: 1.4 }}>Stay on top of revenue without opening the app.</div>

        <Group header="Daily summary">
          <Row last="first" title="Daily reminder" sub="A recap of how much you've made" right={<Toggle on={p.daily} onChange={v => set('daily', v)} />} />
          {p.daily && <Row title="Time" detail={p.dailyTime} onClick={() => nav.push({ type: 'timePicker' })} />}
        </Group>

        <Group header="While you were away">
          <Row last="first" icon="moon" iconBg="#5b6df5" title="Sleep recap" sub="When your phone is in Sleep Focus, get a recap on wake" right={<Toggle on={p.sleep} onChange={v => set('sleep', v)} />} />
          <Row icon="flame" iconBg="#ff9f43" title="Away recap (Focus modes)" sub="Earnings while in Gym, Work or DND" right={<Toggle on={p.away} onChange={v => set('away', v)} />} />
        </Group>

        <Group header="Alerts">
          <Row last="first" title="Goal reached" sub="When you hit a daily / weekly goal" right={<Toggle on={p.goal} onChange={v => set('goal', v)} />} />
          <Row title="Milestone" detail={D.moneyK(p.milestone)} sub="Crossing a revenue threshold today" onClick={() => set('milestone', p.milestone >= 10000 ? 1000 : p.milestone + 1000)} />
          <Row title="Big mover" sub="A day up or down 25%+ vs usual" right={<Toggle on={p.mover} onChange={v => set('mover', v)} />} />
        </Group>

        <button onClick={() => nav.push({ type: 'notifPreview' })} style={{ ...primaryBtn(t), background: t.card, color: t.accent }}>Preview notifications</button>
      </div>
    );
  }

  // time picker sheet
  function TimePicker() {
    const t = window.useT();
    const nav = window.useNav();
    const times = ['7:00 AM', '8:00 AM', '9:00 AM', '12:00 PM', '6:00 PM', '8:00 PM', '9:00 PM', '10:00 PM', '11:00 PM'];
    return (
      <div style={{ padding: '6px 16px 28px' }}>
        <div style={{ fontSize: 14, color: t.sec, margin: '6px 4px 14px' }}>When should we send your daily revenue recap?</div>
        <Card pad={0}>
          {times.map((tm, i) => (
            <div key={tm} onClick={() => { nav.setPrefs({ ...nav.prefs, dailyTime: tm }); nav.pop(); }} style={{ display: 'flex', alignItems: 'center', padding: '14px 16px', cursor: 'pointer', borderTop: i ? `1px solid ${t.hair}` : 'none' }}>
              <span style={{ flex: 1, fontSize: 16, color: t.text }}>{tm}</span>
              {nav.prefs.dailyTime === tm && <Icon name="check" s={18} c={t.accent} sw={3} />}
            </div>
          ))}
        </Card>
      </div>
    );
  }

  // notification preview = a lock screen with banners
  function NotifPreview() {
    const t = window.useT();
    const nav = window.useNav();
    const cmb = D.accountSeries(nav.account);
    const today = D.valueToday(cmb);
    const banners = [
      { icon: 'sparkle', tint: t.accent, app: 'AD REPORT', time: 'now', title: 'Daily recap', body: `You've made ${D.money(today, { dp: 0 })} so far today — ${Math.round(today / D.GOALS.daily * 100)}% of your goal.` },
      { icon: 'moon', tint: '#5b6df5', app: 'AD REPORT', time: '7:02 AM', title: 'While you slept 😴', body: `You earned ${D.money(today * 0.4, { dp: 0 })} overnight across 2 networks.` },
      { icon: 'trophy', tint: t.pos, app: 'AD REPORT', time: 'Yesterday', title: 'Goal reached 🎉', body: `You hit your daily goal of ${D.moneyK(D.GOALS.daily)}. 12-day streak!` },
    ];
    return (
      <div style={{ minHeight: '100%', background: 'linear-gradient(180deg, #1a2535, #0c1118)', padding: '70px 14px 24px', display: 'flex', flexDirection: 'column' }}>
        <div style={{ textAlign: 'center', color: 'rgba(255,255,255,0.85)', marginBottom: 30 }}>
          <div style={{ fontSize: 17, fontWeight: 500 }}>Sunday, June 15</div>
          <div style={{ fontSize: 76, fontWeight: 300, letterSpacing: -2, lineHeight: 1 }}>9:41</div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {banners.map((b, i) => (
            <div key={i} style={{ borderRadius: 22, padding: 14, background: 'rgba(255,255,255,0.13)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)', display: 'flex', gap: 11 }}>
              <div style={{ width: 38, height: 38, borderRadius: 9, background: b.tint, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Icon name={b.icon} s={22} c="#fff" />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: 11.5, fontWeight: 600, color: 'rgba(255,255,255,0.6)', letterSpacing: 0.3 }}>{b.app}</span>
                  <span style={{ fontSize: 12, color: 'rgba(255,255,255,0.5)' }}>{b.time}</span>
                </div>
                <div style={{ fontSize: 15, fontWeight: 700, color: '#fff', marginTop: 2 }}>{b.title}</div>
                <div style={{ fontSize: 14, color: 'rgba(255,255,255,0.85)', marginTop: 1, lineHeight: 1.3 }}>{b.body}</div>
              </div>
            </div>
          ))}
        </div>
        <div style={{ flex: 1 }} />
        <button onClick={() => nav.pop()} style={{ ...primaryBtn(t), background: 'rgba(255,255,255,0.2)', color: '#fff' }}>Done</button>
      </div>
    );
  }

  // ───────────────────────────── Configure networks ─────────────────────────────
  function Configure({ adding }) {
    const t = window.useT();
    const nav = window.useNav();
    const [admob, setAdmob] = useState(!adding);
    const [key, setKey] = useState(adding ? '' : 'AeuaBOElKtqgxMwLdvDEGN07QTX…');
    return (
      <div style={{ padding: '0 16px 28px' }}>
        <div style={{ fontSize: 14, color: t.sec, margin: '2px 4px 18px', lineHeight: 1.4 }}>Connect your ad networks to pull live revenue. Your keys are stored only on this device.</div>

        <div style={{ fontSize: 13, color: t.sec, fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.3, margin: '0 4px 8px' }}>Google AdMob</div>
        <Card style={{ marginBottom: 8 }}>
          <button onClick={() => setAdmob(true)} style={{
            width: '100%', padding: '14px', borderRadius: 14, border: 'none', cursor: 'pointer',
            background: admob ? t.card2 : '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
            fontSize: 16, fontWeight: 600, color: admob ? t.text : '#202124', fontFamily: 'inherit',
          }}>
            <span style={{ width: 22, height: 22, borderRadius: 999, background: 'conic-gradient(#ea4335 0 25%, #fbbc05 25% 50%, #34a853 50% 75%, #4285f4 75%)', display: 'inline-block' }} />
            {admob ? 'Connected' : 'Sign in with Google'}
            {admob && <Icon name="check" s={18} c={t.pos} sw={3} />}
          </button>
        </Card>
        <div style={{ fontSize: 12.5, color: t.ter, margin: '0 6px 20px', lineHeight: 1.4 }}>Sign in with the Google account that owns your AdMob reports. You may be asked twice — to sign in and to grant report access.</div>

        <div style={{ fontSize: 13, color: t.sec, fontWeight: 600, textTransform: 'uppercase', letterSpacing: 0.3, margin: '0 4px 8px' }}>AppLovin Max</div>
        <Card style={{ marginBottom: 8 }}>
          <input value={key} onChange={e => setKey(e.target.value)} placeholder="Report Key" style={{
            width: '100%', border: 'none', outline: 'none', background: 'transparent',
            fontSize: 16, color: t.text, fontFamily: 'inherit',
          }} />
        </Card>
        <div style={{ fontSize: 12.5, color: t.ter, margin: '0 6px 28px', lineHeight: 1.4 }}>Find it under Account → Keys → Report Key in your AppLovin dashboard.</div>

        <button onClick={() => nav.pop()} style={primaryBtn(t)}>{adding ? 'Add account' : 'Save'}</button>
      </div>
    );
  }

  // ───────────────────────────── Paywall ─────────────────────────────
  function Paywall() {
    const t = window.useT();
    const nav = window.useNav();
    const [plan, setPlan] = useState('lifetime');
    const feats = [
      { icon: 'widget', title: 'Widgets', sub: 'Revenue on your Home & Lock Screen' },
      { icon: 'watch', title: 'Apple Watch', sub: 'Complications and a full watch app' },
      { icon: 'bell', title: 'Smart alerts', sub: 'Sleep recaps, goals & milestones' },
      { icon: 'calendar', title: 'Full history', sub: 'Unlimited daily reports & exports' },
    ];
    return (
      <div style={{ padding: '4px 18px 24px', display: 'flex', flexDirection: 'column', minHeight: '100%' }}>
        <div style={{ textAlign: 'center', marginTop: 6, marginBottom: 22 }}>
          <div style={{ width: 64, height: 64, borderRadius: 18, margin: '0 auto 14px', background: `linear-gradient(135deg, ${t.grad[0]}, ${t.grad[1]})`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon name="sparkle" s={34} c="#fff" />
          </div>
          <div style={{ fontSize: 30, fontWeight: 800, color: t.text, letterSpacing: -0.6 }}>Reporting Pro</div>
          <div style={{ fontSize: 15.5, color: t.sec, marginTop: 4 }}>Unlock everything. Cancel anytime.</div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 16, marginBottom: 24 }}>
          {feats.map(f => (
            <div key={f.title} style={{ display: 'flex', gap: 14, alignItems: 'center' }}>
              <div style={{ width: 40, height: 40, borderRadius: 11, background: t.accentSoft, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Icon name={f.icon} s={22} c={t.accent} />
              </div>
              <div>
                <div style={{ fontSize: 16, fontWeight: 700, color: t.text }}>{f.title}</div>
                <div style={{ fontSize: 13.5, color: t.sec, marginTop: 1 }}>{f.sub}</div>
              </div>
            </div>
          ))}
        </div>

        <div style={{ flex: 1 }} />

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginBottom: 16 }}>
          {[{ k: 'lifetime', n: 'Lifetime', p: '$29.99', s: 'One-time · best value' }, { k: 'annual', n: 'Annual', p: '$19.99/yr', s: '$1.67/mo' }].map(o => {
            const sel = plan === o.k;
            return (
              <button key={o.k} onClick={() => setPlan(o.k)} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px', cursor: 'pointer',
                borderRadius: 16, border: `2px solid ${sel ? t.accent : t.hair}`, background: sel ? t.accentSoft : 'transparent', fontFamily: 'inherit', textAlign: 'left',
              }}>
                <div style={{ width: 24, height: 24, borderRadius: 999, border: `2px solid ${sel ? t.accent : t.ter}`, background: sel ? t.accent : 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  {sel && <Icon name="check" s={13} c={t.accentText} sw={3.5} />}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 16, fontWeight: 700, color: t.text }}>{o.n}</div>
                  <div style={{ fontSize: 13, color: t.sec }}>{o.s}</div>
                </div>
                <div style={{ fontSize: 17, fontWeight: 800, color: t.text }}>{o.p}</div>
              </button>
            );
          })}
        </div>
        <button onClick={() => { nav.setPro(true); nav.pop(); }} style={primaryBtn(t)}>Continue</button>
        <div style={{ textAlign: 'center', fontSize: 13, color: t.ter, marginTop: 14 }}>Restore purchases</div>
      </div>
    );
  }

  window.Screens = Object.assign(window.Screens || {}, { Settings, Notifications, TimePicker, NotifPreview, Configure, Paywall, Toggle, SettingsRow: Row, SettingsGroup: Group });
})();

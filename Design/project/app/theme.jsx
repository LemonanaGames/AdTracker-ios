// theme.jsx — 3 clean/Apple-minimal visual directions + shared icons
// Exposes window.Theme (THEMES, getTheme) and window.Icon

(function () {
  // Each theme is a flat token set. All are clean + minimal; they differ in
  // palette, mood, and light/dark.
  const THEMES = {
    // 1. Reference-inspired: near-black + teal
    midnight: {
      key: 'midnight', label: 'Midnight', dark: true,
      bg: '#000000',
      bg2: '#0c0d0f',
      card: '#1a1c1e',
      card2: '#242629',
      hair: 'rgba(255,255,255,0.08)',
      text: '#ffffff',
      sec: 'rgba(235,235,245,0.62)',
      ter: 'rgba(235,235,245,0.32)',
      accent: '#5cb7c9',
      accentText: '#062227',
      accentSoft: 'rgba(92,183,201,0.16)',
      grad: ['#67c3d4', '#3f95a6'],
      pos: '#4cc38a',
      neg: '#ff6b6b',
      tabActive: '#5cb7c9',
    },
    // 2. True monochrome graphite — most "Apple system settings" minimal
    graphite: {
      key: 'graphite', label: 'Graphite', dark: true,
      bg: '#0a0a0b',
      bg2: '#121214',
      card: '#1c1c1f',
      card2: '#27272b',
      hair: 'rgba(255,255,255,0.07)',
      text: '#f5f5f7',
      sec: 'rgba(235,235,245,0.6)',
      ter: 'rgba(235,235,245,0.3)',
      accent: '#a3e635',
      accentText: '#14210a',
      accentSoft: 'rgba(163,230,53,0.14)',
      grad: ['#bef264', '#84cc16'],
      pos: '#a3e635',
      neg: '#ff6b6b',
      tabActive: '#f5f5f7',
    },
    // 3. Light premium — off-white + indigo
    mist: {
      key: 'mist', label: 'Mist (Light)', dark: false,
      bg: '#f4f4f6',
      bg2: '#ececed',
      card: '#ffffff',
      card2: '#f3f3f5',
      hair: 'rgba(60,60,67,0.1)',
      text: '#16161a',
      sec: 'rgba(60,60,67,0.6)',
      ter: 'rgba(60,60,67,0.32)',
      accent: '#5b5bf0',
      accentText: '#ffffff',
      accentSoft: 'rgba(91,91,240,0.1)',
      grad: ['#6d6df5', '#4a4ad8'],
      pos: '#1f9d57',
      neg: '#e5484d',
      tabActive: '#5b5bf0',
    },
  };

  function getTheme(key) { return THEMES[key] || THEMES.midnight; }

  // ---- icons (stroke-based, sized by `s`) --------------------------------
  function Icon({ name, s = 22, c = 'currentColor', sw = 2, fill = 'none' }) {
    const p = { width: s, height: s, viewBox: '0 0 24 24', fill: 'none',
      stroke: c, strokeWidth: sw, strokeLinecap: 'round', strokeLinejoin: 'round' };
    switch (name) {
      case 'home': return <svg {...p}><path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V20h14V9.5"/></svg>;
      case 'chart': return <svg {...p}><path d="M4 20V10M10 20V4M16 20v-7M22 20H2"/></svg>;
      case 'target': return <svg {...p}><circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="4.5"/><circle cx="12" cy="12" r="0.6" fill={c}/></svg>;
      case 'pulse': return <svg {...p}><path d="M2 12h4l2.5-7 4 15 2.5-8h7"/></svg>;
      case 'gear': return <svg {...p}><circle cx="12" cy="12" r="3.2"/><path d="M12 2v3M12 19v3M4.2 4.2l2.1 2.1M17.7 17.7l2.1 2.1M2 12h3M19 12h3M4.2 19.8l2.1-2.1M17.7 6.3l2.1-2.1"/></svg>;
      case 'plus': return <svg {...p}><path d="M12 5v14M5 12h14"/></svg>;
      case 'chevron': return <svg {...p} strokeWidth="2.4"><path d="M9 5l7 7-7 7"/></svg>;
      case 'chevronL': return <svg {...p} strokeWidth="2.4"><path d="M15 5l-7 7 7 7"/></svg>;
      case 'chevronD': return <svg {...p} strokeWidth="2.4"><path d="M5 9l7 7 7-7"/></svg>;
      case 'check': return <svg {...p} strokeWidth="2.6"><path d="M4 12.5l5 5L20 6"/></svg>;
      case 'bell': return <svg {...p}><path d="M6 9a6 6 0 1 1 12 0c0 5 2 6 2 6H4s2-1 2-6"/><path d="M10 20a2 2 0 0 0 4 0"/></svg>;
      case 'moon': return <svg {...p}><path d="M20 14.5A8 8 0 0 1 9.5 4 8 8 0 1 0 20 14.5Z"/></svg>;
      case 'clock': return <svg {...p}><circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/></svg>;
      case 'flame': return <svg {...p}><path d="M12 3c1 3-2 4-2 7a3 3 0 0 0 6 0c0-1-.4-2-1-2.6.2 2.4-1.5 2.6-1.5 1.1C13 6.5 12 4.5 12 3Z"/><path d="M8.5 12a3.5 3.5 0 1 0 7 0"/></svg>;
      case 'arrowUp': return <svg {...p} strokeWidth="2.4"><path d="M12 19V5M6 11l6-6 6 6"/></svg>;
      case 'arrowDown': return <svg {...p} strokeWidth="2.4"><path d="M12 5v14M6 13l6 6 6-6"/></svg>;
      case 'wallet': return <svg {...p}><rect x="3" y="6" width="18" height="13" rx="2.5"/><path d="M3 10h18M16 14h2"/></svg>;
      case 'calendar': return <svg {...p}><rect x="3.5" y="5" width="17" height="16" rx="2.5"/><path d="M3.5 9.5h17M8 3v4M16 3v4"/></svg>;
      case 'watch': return <svg {...p}><rect x="7" y="7" width="10" height="10" rx="3"/><path d="M9 7l.6-3.2A1.5 1.5 0 0 1 11 2.5h2a1.5 1.5 0 0 1 1.4 1.3L15 7M15 17l-.6 3.2A1.5 1.5 0 0 1 13 21.5h-2a1.5 1.5 0 0 1-1.4-1.3L9 17"/></svg>;
      case 'widget': return <svg {...p}><rect x="3.5" y="3.5" width="7.5" height="7.5" rx="2"/><rect x="13" y="3.5" width="7.5" height="7.5" rx="2"/><rect x="3.5" y="13" width="7.5" height="7.5" rx="2"/><rect x="13" y="13" width="7.5" height="7.5" rx="2"/></svg>;
      case 'sparkle': return <svg {...p} fill={c} stroke="none"><path d="M12 2l1.6 5.4L19 9l-5.4 1.6L12 16l-1.6-5.4L5 9l5.4-1.6z"/></svg>;
      case 'dollar': return <svg {...p}><path d="M12 2v20M16.5 6.5C16 5 14.5 4 12 4 9 4 7.5 5.5 7.5 7.5S9.5 10.5 12 11s4.5 1.3 4.5 3.8S14.5 19.5 12 19.5c-2.7 0-4-1-4.7-2.5"/></svg>;
      case 'trophy': return <svg {...p}><path d="M7 4h10v4a5 5 0 0 1-10 0V4Z"/><path d="M7 5H4v2a3 3 0 0 0 3 3M17 5h3v2a3 3 0 0 1-3 3M9 19h6M10 15.5V19M14 15.5V19"/></svg>;
      case 'dots': return <svg {...p} fill={c} stroke="none"><circle cx="5" cy="12" r="1.8"/><circle cx="12" cy="12" r="1.8"/><circle cx="19" cy="12" r="1.8"/></svg>;
      case 'x': return <svg {...p} strokeWidth="2.4"><path d="M6 6l12 12M18 6 6 18"/></svg>;
      case 'share': return <svg {...p}><path d="M12 15V3M8.5 6.5 12 3l3.5 3.5"/><path d="M5 12v6a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-6"/></svg>;
      case 'eye': return <svg {...p}><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>;
      case 'cursor': return <svg {...p}><path d="M5 3l5 17 2.5-6.5L19 11 5 3Z"/></svg>;
      case 'pie': return <svg {...p}><path d="M12 3a9 9 0 1 0 9 9h-9V3Z"/><path d="M12 3v9h9A9 9 0 0 0 12 3Z" opacity="0.45"/></svg>;
      case 'mega': return <svg {...p}><path d="M3 11v2a1 1 0 0 0 1 1h2l5 4V6L6 10H4a1 1 0 0 0-1 1Z"/><path d="M15 8a4 4 0 0 1 0 8M18 5a8 8 0 0 1 0 14"/></svg>;
      case 'coin': return <svg {...p}><circle cx="12" cy="12" r="9"/><path d="M14.5 9c-.5-1-1.5-1.4-2.5-1.4-1.4 0-2.3.8-2.3 1.9 0 2.6 5 1.4 5 4.1 0 1.2-1 2-2.6 2-1.2 0-2.2-.5-2.6-1.5M12 6v1.6M12 16.4V18"/></svg>;
      case 'globe': return <svg {...p}><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c2.5 2.5 2.5 15 0 18M12 3c-2.5 2.5-2.5 15 0 18"/></svg>;
      case 'layers': return <svg {...p}><path d="M12 3l9 5-9 5-9-5 9-5Z"/><path d="M3 13l9 5 9-5"/></svg>;
      case 'apps': return <svg {...p}><rect x="3.5" y="3.5" width="7" height="7" rx="2"/><rect x="13.5" y="3.5" width="7" height="7" rx="2"/><rect x="3.5" y="13.5" width="7" height="7" rx="2"/><rect x="13.5" y="13.5" width="7" height="7" rx="2"/></svg>;
      default: return <svg {...p}><circle cx="12" cy="12" r="9"/></svg>;
    }
  }

  window.Theme = { THEMES, getTheme };
  window.Icon = Icon;
})();

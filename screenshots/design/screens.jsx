/* App Store screenshots for Voidpen — 1242×2688 each.
   Drawn as React components, rendered inside <DCArtboard>s on a design canvas. */

const W = 1242;
const H = 2688;

// ============================================================ SHARED ATOMS

const Wordmark = ({ color = '#1A1410', size = 38 }) => (
  <div style={{
    display: 'flex', alignItems: 'center', gap: 14,
    fontFamily: '"Bricolage Grotesque", sans-serif',
    fontWeight: 700, fontSize: size, letterSpacing: '-0.02em',
    color,
  }}>
    <div style={{
      width: size * 1.05, height: size * 1.05, borderRadius: size * 0.26,
      background: 'linear-gradient(135deg, #FF7A1F 0%, #F25C12 100%)',
      display: 'grid', placeItems: 'center',
      boxShadow: '0 6px 14px rgba(242,92,18,0.32), inset 0 1px 0 rgba(255,255,255,0.4)',
    }}>
      <svg width={size * 0.55} height={size * 0.55} viewBox="0 0 24 24" fill="none">
        <path d="M12 2c0 4-5 5-5 11a5 5 0 0 0 10 0c0-2-1-3-2-4 0 2-1 3-2 3 0-3 2-5-1-10z" fill="#fff" />
      </svg>
    </div>
    <span>voidpen</span>
  </div>
);

// Photo phone (background-image asset inside bezel)
const Phone = ({ src, tilt = 0, scale = 1, offsetY = 0, offsetX = 0, z, dim = 0 }) => {
  const baseW = 1000;
  const w = baseW * scale;
  const h = w * (2622 / 1206);
  const radius = w * 0.092;
  return (
    <div style={{
      position: 'absolute', left: '50%', top: '50%',
      width: w, height: h,
      transform: `translate(calc(-50% + ${offsetX}px), calc(-50% + ${offsetY}px)) rotate(${tilt}deg)`,
      borderRadius: radius,
      background: '#000', padding: 12, zIndex: z,
      boxShadow: '0 80px 120px -30px rgba(20,8,2,0.55), 0 30px 60px -20px rgba(20,8,2,0.40), 0 0 0 2px rgba(0,0,0,0.6)',
    }}>
      <div style={{
        width: '100%', height: '100%', borderRadius: radius - 12,
        overflow: 'hidden', position: 'relative',
        background: `url(${src}) center top / cover, #F4EDE0`,
      }}>
        {dim > 0 && <div style={{ position: 'absolute', inset: 0, background: `rgba(10,5,2,${dim})` }} />}
      </div>
    </div>
  );
};

// React-rendered phone (children render in 1182×2598 coord space, fit to bezel)
const MockPhone = ({ children, tilt = 0, scale = 1, offsetX = 0, offsetY = 0, dim = 0, z = 1 }) => {
  const baseW = 1000;
  const w = baseW * scale;
  const h = w * (2622 / 1206);
  const radius = w * 0.092;
  const innerW = 1182, innerH = 2598;
  const fit = (w - 24) / innerW;
  return (
    <div style={{
      position: 'absolute', left: '50%', top: '50%',
      width: w, height: h,
      transform: `translate(calc(-50% + ${offsetX}px), calc(-50% + ${offsetY}px)) rotate(${tilt}deg)`,
      borderRadius: radius,
      background: '#000', padding: 12, zIndex: z,
      boxShadow: '0 80px 120px -30px rgba(0,0,0,0.7), 0 30px 60px -20px rgba(0,0,0,0.5), 0 0 0 2px rgba(0,0,0,0.6)',
    }}>
      <div style={{
        width: '100%', height: '100%', borderRadius: radius - 12,
        overflow: 'hidden', position: 'relative', background: '#F4EDE0',
      }}>
        <div style={{
          width: innerW, height: innerH,
          transform: `scale(${fit})`, transformOrigin: 'top left',
          position: 'absolute', top: 0, left: 0,
        }}>
          {children}
        </div>
        {dim > 0 && <div style={{ position: 'absolute', inset: 0, background: `rgba(10,5,2,${dim})` }} />}
      </div>
    </div>
  );
};

const Pill = ({ children, bg = '#fff', color = '#1A1410', style = {} }) => (
  <div style={{
    display: 'inline-flex', alignItems: 'center', gap: 14,
    padding: '20px 32px', borderRadius: 999,
    background: bg, color,
    fontFamily: '"Manrope", sans-serif', fontWeight: 600, fontSize: 32,
    boxShadow: '0 14px 30px -10px rgba(20,8,2,0.25)',
    ...style,
  }}>{children}</div>
);

const MiniStatus = ({ dark = false, time = '9:41' }) => (
  <div style={{
    height: 110, display: 'flex', justifyContent: 'space-between', alignItems: 'center',
    padding: '40px 80px 0', fontFamily: '"Manrope", sans-serif', fontWeight: 600, fontSize: 38,
    color: dark ? '#fff' : '#1A1410',
  }}>
    <span>{time}</span>
    <div style={{ width: 320, height: 70, borderRadius: 999, background: '#000' }} />
    <span style={{ fontSize: 32, letterSpacing: 4 }}>•••</span>
  </div>
);

// Frame header (logo + counter) repeated across screenshots
const FrameHeader = ({ counter, color = '#1A1410' }) => (
  <>
    <div style={{ position: 'absolute', top: 110, left: 80 }}>
      <Wordmark color={color} size={42} />
    </div>
    <div style={{
      position: 'absolute', top: 124, right: 80,
      fontFamily: '"Manrope", sans-serif', fontWeight: 600, fontSize: 28,
      letterSpacing: '0.18em', color, opacity: 0.55,
    }}>{counter}</div>
  </>
);

// ============================================================ MOCK UIs

// ---- Voice mock (backing phone in slot 1)
const VoiceUI = () => (
  <div style={{ width: '100%', height: '100%', background: '#F4EDE0', position: 'relative', fontFamily: '"Manrope", sans-serif' }}>
    <MiniStatus />
    <div style={{ textAlign: 'center', marginTop: 100, fontSize: 56, fontWeight: 700, color: '#1A1410' }}>Voice</div>
    <div style={{ textAlign: 'center', marginTop: 16, fontSize: 36, color: '#8A6F55' }}>Listening…</div>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 22, marginTop: 280, height: 460 }}>
      {[0.25,0.55,0.85,0.40,0.95,0.62,1.00,0.72,0.42,0.92,0.55,0.30,0.78,0.65,0.42,0.70,0.50,0.30].map((bh, i) => (
        <div key={i} style={{ width: 30, height: bh * 420, borderRadius: 99, background: 'linear-gradient(180deg, #FF8A3D 0%, #F25C12 100%)' }} />
      ))}
    </div>
    <div style={{ textAlign: 'center', padding: '0 100px', marginTop: 120, fontSize: 48, color: '#1A1410', fontWeight: 500, lineHeight: 1.3 }}>
      “Two slices sourdough,<br />avocado, two eggs…”
    </div>
    <div style={{ position: 'absolute', bottom: 220, left: '50%', transform: 'translateX(-50%)', width: 300, height: 300, borderRadius: 999, background: '#F25C12', display: 'grid', placeItems: 'center', boxShadow: '0 0 80px rgba(242,92,18,0.55), inset 0 4px 0 rgba(255,255,255,0.25)' }}>
      <svg width="120" height="120" viewBox="0 0 24 24" fill="none">
        <rect x="9" y="2" width="6" height="13" rx="3" fill="#fff" />
        <path d="M5 11a7 7 0 0 0 14 0M12 19v3" stroke="#fff" strokeWidth="2.2" strokeLinecap="round" />
      </svg>
    </div>
  </div>
);

// ---- Barcode mock (backing phone in slot 1)
const BarcodeUI = () => (
  <div style={{ width: '100%', height: '100%', background: '#0A0806', position: 'relative', overflow: 'hidden' }}>
    <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(ellipse at center, #2A2018 0%, #0A0806 80%)' }} />
    <div style={{ position: 'relative', zIndex: 2 }}><MiniStatus dark /></div>
    <div style={{ position: 'absolute', top: 230, left: 0, right: 0, textAlign: 'center', color: '#fff', fontSize: 56, fontWeight: 700, fontFamily: '"Manrope", sans-serif' }}>Scan</div>
    <div style={{ position: 'absolute', top: 320, left: 0, right: 0, textAlign: 'center', color: 'rgba(255,255,255,0.65)', fontSize: 34, fontFamily: '"Manrope", sans-serif' }}>Point at a barcode</div>
    <div style={{ position: 'absolute', top: 760, left: 110, right: 110, height: 900 }}>
      {['TL','TR','BL','BR'].map(c => {
        const s = { position: 'absolute', width: 110, height: 110 };
        if (c.includes('T')) s.top = 0; else s.bottom = 0;
        if (c.includes('L')) s.left = 0; else s.right = 0;
        const rot = { TL: 0, TR: 90, BR: 180, BL: 270 }[c];
        return (
          <div key={c} style={{ ...s, transform: `rotate(${rot}deg)` }}>
            <div style={{ position: 'absolute', top: 0, left: 0, width: 110, height: 14, background: '#F25C12', borderRadius: 4 }} />
            <div style={{ position: 'absolute', top: 0, left: 0, width: 14, height: 110, background: '#F25C12', borderRadius: 4 }} />
          </div>
        );
      })}
      <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', display: 'flex', gap: 6, alignItems: 'center' }}>
        {[3,1,2,1,1,3,2,1,3,1,1,2,1,3,2,1,1,2,3,1,2,1].map((bw, i) => (
          <div key={i} style={{ width: bw * 9, height: 320, background: '#fff' }} />
        ))}
      </div>
      <div style={{ position: 'absolute', top: '50%', left: 40, right: 40, height: 5, background: '#F25C12', boxShadow: '0 0 24px 4px rgba(242,92,18,0.7)' }} />
    </div>
  </div>
);

// ---- Text composer mock (backing phone in slot 1)
const NoteUI = () => (
  <div style={{ width: '100%', height: '100%', background: '#F4EDE0', position: 'relative', fontFamily: '"Manrope", sans-serif' }}>
    <MiniStatus />
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '60px 60px 30px', fontSize: 40 }}>
      <span style={{ color: '#F25C12', fontWeight: 600 }}>Cancel</span>
      <span style={{ color: '#1A1410', fontWeight: 700 }}>Note</span>
      <span style={{ color: '#F25C12', fontWeight: 600 }}>Save</span>
    </div>
    <div style={{ margin: '30px 60px', padding: '44px 48px', borderRadius: 36, background: '#fff', fontSize: 54, color: '#1A1410', lineHeight: 1.35, fontWeight: 500, minHeight: 560 }}>
      Two eggs scrambled,<br />
      one slice sourdough,<br />
      black coffee
      <span style={{ display: 'inline-block', width: 4, height: 64, background: '#F25C12', verticalAlign: 'middle', marginLeft: 4, marginTop: -6 }} />
    </div>
    <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: 880, background: '#CFC4B0', padding: '40px 16px 30px' }}>
      {['QWERTYUIOP'.split(''),'ASDFGHJKL'.split(''),'ZXCVBNM'.split('')].map((row, r) => (
        <div key={r} style={{ display: 'flex', justifyContent: 'center', gap: 12, marginBottom: 16, paddingLeft: r * 28, paddingRight: r * 28 }}>
          {row.map(k => (
            <div key={k} style={{ flex: 1, height: 130, borderRadius: 14, background: '#fff', display: 'grid', placeItems: 'center', fontSize: 48, color: '#1A1410', fontWeight: 500, boxShadow: '0 2px 0 rgba(0,0,0,0.18)' }}>{k}</div>
          ))}
        </div>
      ))}
      <div style={{ display: 'flex', gap: 12, marginTop: 4 }}>
        <div style={{ width: 200, height: 130, borderRadius: 14, background: '#A8997F', display: 'grid', placeItems: 'center', fontSize: 34, color: '#1A1410' }}>123</div>
        <div style={{ flex: 1, height: 130, borderRadius: 14, background: '#fff' }} />
        <div style={{ width: 240, height: 130, borderRadius: 14, background: '#F25C12', display: 'grid', placeItems: 'center', fontSize: 36, color: '#fff', fontWeight: 700 }}>Send</div>
      </div>
    </div>
  </div>
);

// ---- Analyzed meal result (slot 2 hero)
const MacroRing = ({ kcal = 612, pct = 0.62 }) => {
  const r = 200, c = 2 * Math.PI * r;
  return (
    <div style={{ position: 'relative', width: 480, height: 480, flexShrink: 0 }}>
      <svg width={480} height={480} viewBox="-240 -240 480 480">
        <circle r={r} fill="none" stroke="#F7E1CB" strokeWidth={42} />
        <circle r={r} fill="none" stroke="#F25C12" strokeWidth={42}
          strokeDasharray={`${c * pct} ${c}`} strokeLinecap="round"
          transform="rotate(-90)" />
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', textAlign: 'center', fontFamily: '"Bricolage Grotesque", sans-serif' }}>
        <div>
          <div style={{ fontSize: 120, fontWeight: 700, color: '#1A1410', letterSpacing: '-0.04em', lineHeight: 1 }}>{kcal}</div>
          <div style={{ fontSize: 40, fontWeight: 500, color: '#8A6F55', marginTop: 8, fontFamily: '"Manrope", sans-serif' }}>kcal</div>
        </div>
      </div>
    </div>
  );
};

const MacroBar = ({ label, value, pct, color }) => (
  <div>
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', fontFamily: '"Manrope", sans-serif' }}>
      <span style={{ fontSize: 44, fontWeight: 600, color: '#1A1410' }}>{label}</span>
      <span style={{ fontSize: 48, fontWeight: 700, color, fontFamily: '"Bricolage Grotesque", sans-serif', letterSpacing: '-0.02em' }}>{value}</span>
    </div>
    <div style={{ marginTop: 16, height: 22, background: '#F7E1CB', borderRadius: 999, overflow: 'hidden' }}>
      <div style={{ width: `${pct * 100}%`, height: '100%', background: color, borderRadius: 999 }} />
    </div>
  </div>
);

const MealResultUI = () => (
  <div style={{ width: '100%', height: '100%', background: '#F4EDE0', position: 'relative', fontFamily: '"Manrope", sans-serif' }}>
    <MiniStatus />
    {/* food photo */}
    <div style={{
      position: 'absolute', top: 110, left: 0, right: 0, height: 1240,
      backgroundImage: 'url(assets/screen-camera.png)',
      backgroundSize: 'cover', backgroundPosition: 'center 30%',
    }}>
      <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(180deg, rgba(244,237,224,0) 70%, #F4EDE0 100%)' }} />
      {/* sparkle "analyzed" pill */}
      <div style={{ position: 'absolute', top: 50, left: 50, display: 'inline-flex', alignItems: 'center', gap: 18, padding: '20px 32px', borderRadius: 999, background: 'rgba(26,20,16,0.85)', backdropFilter: 'blur(20px)', color: '#FFE2C8', fontSize: 34, fontWeight: 600 }}>
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none">
          <path d="M12 3v4M12 17v4M3 12h4M17 12h4M6 6l2 2M16 16l2 2M6 18l2-2M16 8l2-2" stroke="#FF8A3D" strokeWidth="2.5" strokeLinecap="round" />
        </svg>
        Analyzed · 2.1s
      </div>
      <div style={{ position: 'absolute', top: 50, right: 50, width: 100, height: 100, borderRadius: 999, background: 'rgba(255,255,255,0.85)', display: 'grid', placeItems: 'center', fontSize: 48, color: '#1A1410' }}>×</div>
    </div>

    {/* meal title */}
    <div style={{ position: 'absolute', top: 1280, left: 60, right: 60, fontFamily: '"Bricolage Grotesque", sans-serif' }}>
      <div style={{ fontSize: 34, color: '#8A6F55', fontWeight: 600, fontFamily: '"Manrope", sans-serif', textTransform: 'uppercase', letterSpacing: '0.14em' }}>Lunch · just now</div>
      <div style={{ fontSize: 84, fontWeight: 700, color: '#1A1410', marginTop: 14, letterSpacing: '-0.03em', lineHeight: 1.05 }}>
        Salmon &amp; quinoa bowl
      </div>
    </div>

    {/* result card */}
    <div style={{ position: 'absolute', top: 1560, left: 60, right: 60, padding: 50, borderRadius: 56, background: '#fff', boxShadow: '0 30px 60px -20px rgba(20,8,2,0.08)' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 50 }}>
        <MacroRing kcal={612} pct={0.62} />
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 40 }}>
          <MacroBar label="Protein" value="38 g" pct={0.78} color="#F25C12" />
          <MacroBar label="Carbs"   value="54 g" pct={0.55} color="#FF8A3D" />
          <MacroBar label="Fat"     value="22 g" pct={0.42} color="#FFB169" />
        </div>
      </div>
    </div>

    {/* CTA */}
    <div style={{ position: 'absolute', bottom: 120, left: 60, right: 60, height: 150, borderRadius: 75, background: '#F25C12', color: '#fff', display: 'grid', placeItems: 'center', fontSize: 50, fontWeight: 600, fontFamily: '"Manrope", sans-serif', boxShadow: '0 20px 40px -10px rgba(242,92,18,0.5)' }}>
      Save to today
    </div>
  </div>
);

// ---- Coach chat mock (slot 4 hero) — pizza question
const Bubble = ({ children, from = 'coach' }) => {
  const isUser = from === 'user';
  return (
    <div style={{
      alignSelf: isUser ? 'flex-end' : 'flex-start',
      maxWidth: 880, padding: '32px 40px',
      borderRadius: isUser ? '44px 44px 12px 44px' : '44px 44px 44px 12px',
      background: isUser ? '#F25C12' : '#FFF7EC',
      color: isUser ? '#fff' : '#1A1410',
      fontSize: 42, fontWeight: 500, lineHeight: 1.32, letterSpacing: '-0.005em',
    }}>{children}</div>
  );
};

const CoachChatUI = () => (
  <div style={{ width: '100%', height: '100%', background: '#F4EDE0', position: 'relative', fontFamily: '"Manrope", sans-serif' }}>
    <MiniStatus />
    {/* header */}
    <div style={{ position: 'absolute', top: 120, left: 0, right: 0, padding: '40px 60px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
      <div style={{ width: 90, height: 90, borderRadius: 999, background: '#FFF7EC', display: 'grid', placeItems: 'center', fontSize: 50, color: '#F25C12', fontWeight: 700 }}>‹</div>
      <div style={{ textAlign: 'center', fontFamily: '"Bricolage Grotesque", sans-serif' }}>
        <div style={{ fontSize: 44, fontWeight: 700, color: '#1A1410', letterSpacing: '-0.02em' }}>Coach</div>
        <div style={{ fontSize: 26, color: '#8A6F55', marginTop: 4, fontFamily: '"Manrope", sans-serif' }}>
          <span style={{ display: 'inline-block', width: 14, height: 14, borderRadius: 999, background: '#3AB87E', verticalAlign: 'middle', marginRight: 10 }} />
          online · knows your data
        </div>
      </div>
      <div style={{ width: 90, height: 90, borderRadius: 999, background: '#FFF7EC', display: 'grid', placeItems: 'center', fontSize: 40, color: '#F25C12' }}>···</div>
    </div>

    {/* messages */}
    <div style={{ position: 'absolute', top: 360, left: 60, right: 60, display: 'flex', flexDirection: 'column', gap: 40 }}>
      {/* date pill */}
      <div style={{ alignSelf: 'center', padding: '14px 28px', borderRadius: 999, background: 'rgba(26,20,16,0.06)', fontSize: 28, color: '#8A6F55', fontWeight: 600 }}>
        Today · 7:42 PM
      </div>

      <Bubble from="user">
        Can I still hit my goal if I eat pizza tonight?
      </Bubble>

      <Bubble from="coach">
        <b>Yep — if you cap it at 3 slices.</b><br /><br />
        You've banked <b>438 kcal</b> and <b>52 g protein</b> today, so you have
        <span style={{ background: '#FFE2C8', padding: '0 10px', borderRadius: 8, margin: '0 4px' }}>1,187 kcal · 63 g protein</span>
        left.
      </Bubble>

      <Bubble from="coach">
        Three slices of cheese pizza ≈ <b>855 kcal · 36 g protein</b>.<br /><br />
        That leaves you <b>332 kcal</b> for a Greek-yogurt snack to close the protein gap. 🍕
      </Bubble>

      {/* typing indicator */}
      <div style={{ alignSelf: 'flex-start', display: 'inline-flex', alignItems: 'center', gap: 14, padding: '24px 32px', borderRadius: 999, background: '#FFF7EC' }}>
        {[0,1,2].map(i => (
          <div key={i} style={{ width: 18, height: 18, borderRadius: 999, background: '#F25C12', opacity: 0.4 + i * 0.2 }} />
        ))}
      </div>
    </div>

    {/* composer */}
    <div style={{ position: 'absolute', bottom: 130, left: 60, right: 60, height: 130, borderRadius: 65, background: '#fff', display: 'flex', alignItems: 'center', padding: '0 30px', gap: 24, boxShadow: '0 -10px 30px rgba(20,8,2,0.05)' }}>
      <div style={{ width: 80, height: 80, borderRadius: 999, background: '#F25C12', display: 'grid', placeItems: 'center', color: '#fff', fontSize: 50, fontWeight: 300 }}>+</div>
      <div style={{ flex: 1, fontSize: 38, color: '#B89B7B' }}>Ask Coach…</div>
      <div style={{ width: 80, height: 80, borderRadius: 999, background: '#E8DCC8', display: 'grid', placeItems: 'center' }}>
        <svg width="40" height="40" viewBox="0 0 24 24" fill="none"><path d="M12 19V5M5 12l7-7 7 7" stroke="#8A6F55" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" /></svg>
      </div>
    </div>
  </div>
);

// ---- Protein detail mock (slot 5 hero)
const ProteinDetailUI = () => {
  const r = 380, c = 2 * Math.PI * r;
  const pct = 104 / 115;
  return (
    <div style={{ width: '100%', height: '100%', background: '#F4EDE0', position: 'relative', fontFamily: '"Manrope", sans-serif' }}>
      <MiniStatus />
      {/* back + title */}
      <div style={{ position: 'absolute', top: 130, left: 60, right: 60, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ width: 96, height: 96, borderRadius: 999, background: '#FFF7EC', display: 'grid', placeItems: 'center', fontSize: 56, color: '#F25C12', fontWeight: 700 }}>‹</div>
        <div style={{ fontFamily: '"Bricolage Grotesque", sans-serif', fontSize: 44, fontWeight: 700, color: '#1A1410', letterSpacing: '-0.02em' }}>Protein</div>
        <div style={{ width: 96, height: 96 }} />
      </div>

      {/* ring */}
      <div style={{ position: 'absolute', top: 320, left: 0, right: 0, display: 'grid', placeItems: 'center' }}>
        <div style={{ position: 'relative', width: 880, height: 880 }}>
          <svg width={880} height={880} viewBox="-440 -440 880 880">
            <circle r={r} fill="none" stroke="#F7E1CB" strokeWidth={72} />
            <circle r={r} fill="none" stroke="#F25C12" strokeWidth={72}
              strokeDasharray={`${c * pct} ${c}`} strokeLinecap="round"
              transform="rotate(-90)" />
            {/* small marker for target */}
          </svg>
          <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', textAlign: 'center', fontFamily: '"Bricolage Grotesque", sans-serif' }}>
            <div>
              <div style={{ fontSize: 50, color: '#8A6F55', fontWeight: 600, fontFamily: '"Manrope", sans-serif', letterSpacing: '0.14em', textTransform: 'uppercase' }}>Protein</div>
              <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'center', gap: 18, marginTop: 24 }}>
                <span style={{ fontSize: 280, fontWeight: 800, color: '#1A1410', letterSpacing: '-0.05em', lineHeight: 1 }}>104</span>
                <span style={{ fontSize: 100, fontWeight: 600, color: '#8A6F55' }}>g</span>
              </div>
              <div style={{ fontSize: 44, color: '#8A6F55', marginTop: 16, fontFamily: '"Manrope", sans-serif' }}>of 115 g · <span style={{ color: '#F25C12', fontWeight: 700 }}>11 g to go</span></div>
            </div>
          </div>
        </div>
      </div>

      {/* breakdown card */}
      <div style={{ position: 'absolute', bottom: 110, left: 60, right: 60, padding: 50, borderRadius: 56, background: '#fff', fontFamily: '"Manrope", sans-serif' }}>
        <div style={{ fontFamily: '"Bricolage Grotesque", sans-serif', fontSize: 40, fontWeight: 700, color: '#1A1410', marginBottom: 32, letterSpacing: '-0.02em' }}>Today by meal</div>
        {[
          ['Breakfast', 'Greek yogurt + berries', 32],
          ['Lunch',     'Salmon quinoa bowl',     38],
          ['Snack',     'Whey shake',              24],
          ['Dinner',    'Add a protein-forward meal', 10],
        ].map(([m, sub, g], i, arr) => (
          <div key={m} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '24px 0', borderBottom: i < arr.length - 1 ? '1px solid rgba(26,20,16,0.06)' : 'none' }}>
            <div>
              <div style={{ fontSize: 40, fontWeight: 700, color: '#1A1410', letterSpacing: '-0.01em' }}>{m}</div>
              <div style={{ fontSize: 30, color: '#8A6F55', marginTop: 4 }}>{sub}</div>
            </div>
            <div style={{ fontSize: 56, fontWeight: 700, color: m === 'Dinner' ? '#8A6F55' : '#F25C12', fontFamily: '"Bricolage Grotesque", sans-serif', letterSpacing: '-0.02em' }}>
              {g} g
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

// ---- Standalone Voidpen protein widget (echoes behind slot 5)
const ProteinWidget = ({ size = 460 }) => {
  const r = size * 0.32, c = 2 * Math.PI * r;
  const pct = 104 / 115;
  return (
    <div style={{
      width: size, height: size, borderRadius: size * 0.22,
      background: '#fff',
      boxShadow: '0 40px 80px -20px rgba(20,8,2,0.35), 0 0 0 1px rgba(255,255,255,0.5)',
      padding: size * 0.07, position: 'relative',
      fontFamily: '"Manrope", sans-serif',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 14, fontSize: size * 0.085, fontWeight: 600, color: '#8A6F55' }}>
        <svg width={size * 0.09} height={size * 0.09} viewBox="0 0 24 24" fill="#F25C12">
          <path d="M13 2L4 14h7l-1 8 9-12h-7l1-8z" />
        </svg>
        Protein
      </div>
      <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center' }}>
        <div style={{ position: 'relative', width: r * 2.4, height: r * 2.4 }}>
          <svg width={r * 2.4} height={r * 2.4} viewBox={`${-r * 1.2} ${-r * 1.2} ${r * 2.4} ${r * 2.4}`}>
            <circle r={r} fill="none" stroke="#FCE6CE" strokeWidth={size * 0.07} />
            <circle r={r} fill="none" stroke="#F25C12" strokeWidth={size * 0.07}
              strokeDasharray={`${c * pct} ${c}`} strokeLinecap="round" transform="rotate(-90)" />
          </svg>
          <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', textAlign: 'center', fontFamily: '"Bricolage Grotesque", sans-serif' }}>
            <div>
              <div style={{ fontSize: size * 0.18, fontWeight: 700, color: '#1A1410', letterSpacing: '-0.04em', lineHeight: 1 }}>104g</div>
              <div style={{ fontSize: size * 0.062, color: '#8A6F55', marginTop: 6 }}>/ 115g</div>
            </div>
          </div>
        </div>
      </div>
      <div style={{ position: 'absolute', bottom: size * 0.06, left: 0, right: 0, textAlign: 'center', fontSize: size * 0.062, color: '#8A6F55', fontWeight: 500 }}>11 g left</div>
    </div>
  );
};

// ---- Progress / weight trend mock (slot 6 hero) — descending line + delta
const ProgressTrendUI = () => {
  // points roughly representing weeks 0..6
  const pts = [
    { x: 60,   y: 220, label: 'Apr 10', w: '149.5' },
    { x: 215,  y: 280, label: 'Apr 17', w: '147.8' },
    { x: 370,  y: 330, label: 'Apr 24', w: '146.4' },
    { x: 525,  y: 405, label: 'May 1',  w: '144.1' },
    { x: 680,  y: 470, label: 'May 8',  w: '142.6' },
    { x: 835,  y: 540, label: 'May 15', w: '141.5' },
    { x: 990,  y: 600, label: 'May 22', w: '141.3' },
  ];
  const path = pts.reduce((acc, p, i) => {
    if (i === 0) return `M ${p.x} ${p.y}`;
    const prev = pts[i - 1];
    const cx1 = prev.x + (p.x - prev.x) * 0.5;
    const cx2 = p.x - (p.x - prev.x) * 0.5;
    return `${acc} C ${cx1} ${prev.y}, ${cx2} ${p.y}, ${p.x} ${p.y}`;
  }, '');
  const last = pts[pts.length - 1];
  // chart in viewBox 0 0 1062 720
  return (
    <div style={{ width: '100%', height: '100%', background: '#F4EDE0', position: 'relative', fontFamily: '"Manrope", sans-serif' }}>
      <MiniStatus />
      {/* segmented */}
      <div style={{ margin: '40px 60px', height: 110, borderRadius: 55, background: 'rgba(202,184,156,0.35)', display: 'flex', alignItems: 'center', padding: 8, fontSize: 38, fontWeight: 600 }}>
        {[['1W',false],['1M',false],['3M',false],['6M',true],['1Y',false],['All',false]].map(([t, on]) => (
          <div key={t} style={{ flex: 1, height: '100%', borderRadius: 50, display: 'grid', placeItems: 'center', background: on ? '#fff' : 'transparent', color: '#1A1410', boxShadow: on ? '0 4px 10px rgba(0,0,0,0.08)' : 'none' }}>{t}</div>
        ))}
      </div>

      {/* tab */}
      <div style={{ margin: '24px 60px 0', height: 110, borderRadius: 55, background: 'rgba(202,184,156,0.35)', display: 'flex', alignItems: 'center', padding: 8, fontSize: 38, fontWeight: 600 }}>
        <div style={{ flex: 1, height: '100%', borderRadius: 50, display: 'grid', placeItems: 'center', background: '#fff', color: '#1A1410', boxShadow: '0 4px 10px rgba(0,0,0,0.08)' }}>Weight</div>
        <div style={{ flex: 1, height: '100%', borderRadius: 50, display: 'grid', placeItems: 'center', color: '#1A1410' }}>Body Fat</div>
      </div>

      {/* main card */}
      <div style={{ position: 'absolute', top: 540, left: 60, right: 60, padding: 50, borderRadius: 56, background: '#FFF7EC' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div style={{ fontFamily: '"Bricolage Grotesque", sans-serif', fontSize: 56, fontWeight: 700, color: '#1A1410', letterSpacing: '-0.02em' }}>Weight</div>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 14, padding: '12px 24px', borderRadius: 999, background: '#F25C12', color: '#fff', fontSize: 30, fontWeight: 600 }}>
            <span style={{ width: 18, height: 18, borderRadius: 999, background: '#fff', display: 'grid', placeItems: 'center', color: '#F25C12', fontSize: 24, fontWeight: 700 }}>+</span>
            Log
          </div>
        </div>

        <div style={{ display: 'flex', gap: 80, marginTop: 36, alignItems: 'baseline', fontFamily: '"Bricolage Grotesque", sans-serif' }}>
          <div>
            <div style={{ fontSize: 90, fontWeight: 700, color: '#1A1410', letterSpacing: '-0.03em', lineHeight: 1 }}>141.3<span style={{ fontSize: 44, color: '#8A6F55', fontWeight: 600 }}> lbs</span></div>
            <div style={{ fontSize: 30, color: '#8A6F55', fontFamily: '"Manrope", sans-serif', marginTop: 6 }}>current</div>
          </div>
          <div>
            <div style={{ fontSize: 64, fontWeight: 700, color: '#8A6F55', letterSpacing: '-0.03em', lineHeight: 1 }}>132 lbs</div>
            <div style={{ fontSize: 30, color: '#8A6F55', fontFamily: '"Manrope", sans-serif', marginTop: 6 }}>goal</div>
          </div>
        </div>

        {/* chart */}
        <div style={{ position: 'relative', marginTop: 50, height: 760 }}>
          <svg viewBox="0 0 1062 720" style={{ width: '100%', height: '100%' }}>
            {/* grid */}
            {[0,1,2,3].map(i => (
              <line key={i} x1={0} x2={1062} y1={120 + i * 160} y2={120 + i * 160}
                stroke="rgba(26,20,16,0.08)" strokeDasharray="4 8" />
            ))}
            {/* goal line */}
            <line x1={0} x2={1062} y1={690} y2={690} stroke="#3AB87E" strokeWidth={3} strokeDasharray="10 10" />
            <text x={1050} y={680} textAnchor="end" fontSize={26} fill="#3AB87E" fontFamily="Manrope" fontWeight="600">goal · 132 lb</text>

            {/* area fill under line */}
            <path d={`${path} L ${last.x} 720 L ${pts[0].x} 720 Z`} fill="url(#grad)" opacity="0.35" />
            <defs>
              <linearGradient id="grad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0" stopColor="#F25C12" stopOpacity="0.6" />
                <stop offset="1" stopColor="#F25C12" stopOpacity="0" />
              </linearGradient>
            </defs>

            {/* main line */}
            <path d={path} fill="none" stroke="#F25C12" strokeWidth={9} strokeLinecap="round" strokeLinejoin="round" />

            {/* dots */}
            {pts.map((p, i) => (
              <g key={i}>
                <circle cx={p.x} cy={p.y} r={i === pts.length - 1 ? 22 : 11} fill="#fff" stroke="#F25C12" strokeWidth={6} />
              </g>
            ))}

            {/* y axis labels */}
            <text x={1055} y={130}  textAnchor="end" fontSize={26} fill="#8A6F55" fontFamily="Manrope" fontWeight="600">150</text>
            <text x={1055} y={450} textAnchor="end" fontSize={26} fill="#8A6F55" fontFamily="Manrope" fontWeight="600">145</text>
            <text x={1055} y={690} textAnchor="end" fontSize={26} fill="#8A6F55" fontFamily="Manrope" fontWeight="600">140</text>
          </svg>

          {/* x labels */}
          <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, display: 'flex', justifyContent: 'space-between', padding: '0 30px', fontSize: 26, color: '#8A6F55', fontWeight: 500 }}>
            <span>Apr 10</span><span>Apr 24</span><span>May 8</span><span>May 22</span>
          </div>
        </div>
      </div>
    </div>
  );
};

// ============================================================ SCREENSHOTS

// ============================================== 01 — Snap. Speak. Scan. Type.
const Screen_PickAnyWay = () => (
  <div style={{
    width: W, height: H, position: 'relative', overflow: 'hidden',
    background: 'radial-gradient(120% 90% at 50% 40%, #2A1A10 0%, #150A06 55%, #050201 100%)',
    fontFamily: '"Bricolage Grotesque", sans-serif',
    color: '#fff',
  }}>
    {/* warm glow behind cluster */}
    <div style={{
      position: 'absolute', top: 900, left: '50%', transform: 'translateX(-50%)',
      width: 1300, height: 1300, borderRadius: 999,
      background: 'radial-gradient(circle, rgba(255,130,40,0.32) 0%, transparent 60%)',
      filter: 'blur(40px)',
    }} />

    <FrameHeader counter="01 / 06" color="#fff" />

    <div style={{ position: 'absolute', top: 240, left: 80, right: 80, zIndex: 10 }}>
      <div style={{ fontSize: 168, fontWeight: 800, lineHeight: 0.92, letterSpacing: '-0.05em' }}>
        SNAP. <span style={{ color: '#FF8A3D' }}>SPEAK.</span><br />
        SCAN. <span style={{ color: '#FF8A3D' }}>TYPE.</span>
      </div>
      <div style={{
        marginTop: 36, fontFamily: '"Manrope", sans-serif',
        fontSize: 42, fontWeight: 500, lineHeight: 1.3,
        color: 'rgba(255,235,220,0.85)', letterSpacing: '-0.005em',
      }}>
        Log meals any way you want.
      </div>
    </div>

    {/* 3 backing phones */}
    <MockPhone tilt={-22} scale={0.82} offsetX={-620} offsetY={960} z={1} dim={0.55}><NoteUI /></MockPhone>
    <MockPhone tilt={-11} scale={0.86} offsetX={-300} offsetY={920} z={2} dim={0.32}><VoiceUI /></MockPhone>
    <MockPhone tilt={11}  scale={0.86} offsetX={300}  offsetY={920} z={2} dim={0.32}><BarcodeUI /></MockPhone>

    {/* HERO — input picker sheet, all 7 icons */}
    <Phone src="assets/screen-addfood.png" scale={0.94} offsetY={900} z={5} />

    {/* badge under hero */}
    <div style={{ position: 'absolute', bottom: 130, left: '50%', transform: 'translateX(-50%)', zIndex: 6 }}>
      <Pill bg="#1A1410" color="#FFE2C8">
        <span style={{ width: 14, height: 14, borderRadius: 999, background: '#FF9A4A', boxShadow: '0 0 16px #FF9A4A' }} />
        7 ways to log a meal
      </Pill>
    </div>
  </div>
);

// ============================================== 02 — AI reads your plate
const Screen_AIReads = () => (
  <div style={{
    width: W, height: H, position: 'relative', overflow: 'hidden',
    background: 'radial-gradient(120% 80% at 50% 10%, #FF8A3D 0%, #F25C12 45%, #B33808 100%)',
    fontFamily: '"Bricolage Grotesque", sans-serif',
  }}>
    <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(60% 40% at 50% 0%, rgba(255,220,180,0.35) 0%, transparent 60%)', mixBlendMode: 'screen' }} />

    <FrameHeader counter="02 / 06" color="#fff" />

    <div style={{ position: 'absolute', top: 240, left: 80, right: 80, color: '#fff' }}>
      <div style={{ fontSize: 156, fontWeight: 800, lineHeight: 0.92, letterSpacing: '-0.05em' }}>
        AI reads<br />
        <span style={{ fontStyle: 'italic', fontWeight: 600, color: '#FFE2C8' }}>your plate.</span>
      </div>
      <div style={{
        marginTop: 36, fontFamily: '"Manrope", sans-serif',
        fontSize: 42, fontWeight: 500, lineHeight: 1.3,
        color: 'rgba(255,240,224,0.92)', maxWidth: 980, letterSpacing: '-0.005em',
      }}>
        Photo → macros in <b style={{ color: '#fff' }}>2&nbsp;seconds</b>.
      </div>
    </div>

    {/* faded raw camera preview phone, BEHIND, left */}
    <Phone src="assets/screen-camera.png" tilt={-9} scale={0.78} offsetX={-380} offsetY={920} z={1} dim={0.45} />

    {/* HERO — analyzed result */}
    <MockPhone scale={0.96} offsetX={140} offsetY={920} z={5}>
      <MealResultUI />
    </MockPhone>

    {/* big forward arrow between */}
    <svg style={{ position: 'absolute', top: 1620, left: 360, zIndex: 4, filter: 'drop-shadow(0 12px 24px rgba(20,8,2,0.4))' }} width="220" height="160" viewBox="0 0 220 160" fill="none">
      <path d="M10 80 H 180 M 130 30 L 200 80 L 130 130" stroke="#FFE2C8" strokeWidth="14" strokeLinecap="round" strokeLinejoin="round" />
    </svg>

    {/* badge */}
    <div style={{ position: 'absolute', bottom: 130, right: 80, zIndex: 6 }}>
      <Pill bg="#1A1410" color="#FFE2C8">
        <span style={{ width: 14, height: 14, borderRadius: 999, background: '#FF9A4A', boxShadow: '0 0 16px #FF9A4A' }} />
        96% accurate · learns your habits
      </Pill>
    </div>
  </div>
);

// ============================================== 03 — Glance at your macros (widgets)
const Screen_Widgets = () => (
  <div style={{
    width: W, height: H, position: 'relative', overflow: 'hidden',
    background: 'linear-gradient(160deg, #E8C8B8 0%, #C9B5C8 50%, #A8B8C8 100%)',
    fontFamily: '"Bricolage Grotesque", sans-serif',
  }}>
    <div style={{ position: 'absolute', top: -100, left: -100, width: 700, height: 700, borderRadius: 999, background: 'radial-gradient(circle, rgba(255,140,80,0.35) 0%, transparent 60%)', filter: 'blur(40px)' }} />
    <div style={{ position: 'absolute', bottom: 200, right: -200, width: 800, height: 800, borderRadius: 999, background: 'radial-gradient(circle, rgba(140,180,220,0.5) 0%, transparent 60%)', filter: 'blur(40px)' }} />

    <FrameHeader counter="03 / 06" color="#fff" />

    <div style={{ position: 'absolute', top: 240, left: 80, right: 80, color: '#fff', textShadow: '0 2px 20px rgba(0,0,0,0.18)' }}>
      <div style={{ fontSize: 150, fontWeight: 700, lineHeight: 0.94, letterSpacing: '-0.045em' }}>
        Glance at<br />
        your <span style={{ fontStyle: 'italic', fontWeight: 500 }}>macros.</span>
      </div>
      <div style={{
        marginTop: 32, fontFamily: '"Manrope", sans-serif',
        fontSize: 40, fontWeight: 500, lineHeight: 1.3, maxWidth: 900,
        opacity: 0.95, letterSpacing: '-0.005em',
      }}>
        Right from your home screen — no app open required.
      </div>
    </div>

    <Phone src="assets/screen-widgets.png" scale={0.94} offsetY={820} />

    {/* pointer call-outs */}
    <div style={{ position: 'absolute', top: 1320, left: 70, transform: 'rotate(-3deg)', zIndex: 10 }}>
      <Pill bg="#1A1410" color="#FFE2C8" style={{ fontSize: 28 }}>
        Calorie ring
      </Pill>
    </div>
    <div style={{ position: 'absolute', top: 1320, right: 70, transform: 'rotate(3deg)', zIndex: 10 }}>
      <Pill bg="#1A1410" color="#FFE2C8" style={{ fontSize: 28 }}>
        Protein widget
      </Pill>
    </div>
  </div>
);

// ============================================== 04 — Chat with your AI coach
const Screen_Coach = () => (
  <div style={{
    width: W, height: H, position: 'relative', overflow: 'hidden',
    background: 'linear-gradient(180deg, #FFF1E1 0%, #F8DFC0 100%)',
    fontFamily: '"Bricolage Grotesque", sans-serif',
  }}>
    <div style={{ position: 'absolute', top: -200, right: -200, width: 900, height: 900, borderRadius: 999, background: 'radial-gradient(circle, rgba(255,140,60,0.35) 0%, transparent 60%)' }} />
    <div style={{ position: 'absolute', bottom: -200, left: -200, width: 800, height: 800, borderRadius: 999, background: 'radial-gradient(circle, rgba(255,180,120,0.28) 0%, transparent 60%)' }} />

    <FrameHeader counter="04 / 06" />

    <div style={{ position: 'absolute', top: 240, left: 80, right: 80, color: '#1A1410' }}>
      <div style={{ fontSize: 150, fontWeight: 700, lineHeight: 0.94, letterSpacing: '-0.045em' }}>
        Chat with<br />
        your <span style={{ fontStyle: 'italic', fontWeight: 500, color: '#F25C12' }}>AI&nbsp;coach.</span>
      </div>
      <div style={{
        marginTop: 32, fontFamily: '"Manrope", sans-serif',
        fontSize: 40, fontWeight: 500, lineHeight: 1.3, color: '#5C3A20',
        letterSpacing: '-0.005em',
      }}>
        Ask anything. Get real answers — shaped by your own data.
      </div>
    </div>

    {/* HERO — chat thread */}
    <MockPhone scale={0.96} offsetY={920} z={5}>
      <CoachChatUI />
    </MockPhone>

    {/* hand-drawn arrow pointing at user bubble */}
    <svg style={{ position: 'absolute', top: 1580, left: 70, zIndex: 6 }} width="280" height="200" viewBox="0 0 280 200" fill="none">
      <path d="M 20 160 C 80 80, 160 60, 260 80" stroke="#F25C12" strokeWidth="6" strokeLinecap="round" fill="none" strokeDasharray="2 14" />
      <path d="M 240 60 L 270 80 L 240 100" stroke="#F25C12" strokeWidth="6" strokeLinecap="round" strokeLinejoin="round" fill="none" />
    </svg>
    <div style={{ position: 'absolute', top: 1740, left: 80, zIndex: 6, transform: 'rotate(-6deg)', maxWidth: 360, fontFamily: '"Bricolage Grotesque", sans-serif', fontSize: 40, fontWeight: 600, color: '#F25C12', lineHeight: 1.1, letterSpacing: '-0.02em' }}>
      Real macro<br />math — not vibes.
    </div>
  </div>
);

// ============================================== 05 — Hit your protein goal
const Screen_Protein = () => (
  <div style={{
    width: W, height: H, position: 'relative', overflow: 'hidden',
    background: '#F4EDE0',
    fontFamily: '"Bricolage Grotesque", sans-serif',
  }}>
    <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(70% 50% at 80% 20%, rgba(255,170,90,0.25) 0%, transparent 70%)' }} />

    <FrameHeader counter="05 / 06" />

    <div style={{ position: 'absolute', top: 240, left: 80, right: 80, color: '#1A1410' }}>
      <div style={{ fontSize: 150, fontWeight: 700, lineHeight: 0.94, letterSpacing: '-0.045em' }}>
        Hit your<br />
        <span style={{ color: '#F25C12' }}>protein</span> goal.
      </div>
      <div style={{
        marginTop: 32, fontFamily: '"Manrope", sans-serif',
        fontSize: 40, fontWeight: 500, lineHeight: 1.3, color: '#5C3A20',
        letterSpacing: '-0.005em',
      }}>
        Every gram counts — and you can see exactly where they're coming from.
      </div>
    </div>

    {/* echo widget behind hero — top right, tilted */}
    <div style={{ position: 'absolute', top: 1100, right: -60, transform: 'rotate(8deg)', zIndex: 1 }}>
      <ProteinWidget size={460} />
    </div>
    {/* echo widget bottom left */}
    <div style={{ position: 'absolute', bottom: 220, left: -40, transform: 'rotate(-6deg)', zIndex: 1, opacity: 0.85 }}>
      <ProteinWidget size={360} />
    </div>

    {/* HERO */}
    <MockPhone scale={0.94} offsetY={840} z={5}>
      <ProteinDetailUI />
    </MockPhone>

    {/* "+11g" floating delta */}
    <div style={{ position: 'absolute', top: 1240, right: 130, zIndex: 10, transform: 'rotate(6deg)' }}>
      <div style={{
        padding: '24px 36px', borderRadius: 28,
        background: '#1A1410', color: '#fff',
        fontFamily: '"Bricolage Grotesque", sans-serif',
        boxShadow: '0 24px 50px -15px rgba(20,8,2,0.4)',
      }}>
        <div style={{ fontSize: 30, color: '#FF8A3D', fontFamily: '"Manrope", sans-serif', fontWeight: 600 }}>11 g to go</div>
        <div style={{ fontSize: 70, fontWeight: 800, letterSpacing: '-0.03em', lineHeight: 1, marginTop: 6 }}>1 snack away</div>
      </div>
    </div>
  </div>
);

// ============================================== 06 — Watch your progress trend
const Screen_Progress = () => (
  <div style={{
    width: W, height: H, position: 'relative', overflow: 'hidden',
    background: '#EFE6D6',
    fontFamily: '"Bricolage Grotesque", sans-serif',
  }}>
    <div style={{
      position: 'absolute', inset: 0, opacity: 0.5,
      backgroundImage: 'radial-gradient(circle, rgba(120,80,40,0.15) 1.5px, transparent 2px)',
      backgroundSize: '38px 38px',
    }} />

    <FrameHeader counter="06 / 06" />

    <div style={{ position: 'absolute', top: 240, left: 80, right: 80, color: '#1A1410' }}>
      <div style={{ fontSize: 138, fontWeight: 700, lineHeight: 0.94, letterSpacing: '-0.045em' }}>
        Watch the <span style={{ color: '#F25C12' }}>trend</span>,<br />
        not the day.
      </div>
      <div style={{
        marginTop: 32, fontFamily: '"Manrope", sans-serif',
        fontSize: 40, fontWeight: 500, lineHeight: 1.3, color: '#5C3A20',
        letterSpacing: '-0.005em',
      }}>
        Down <b style={{ color: '#1A1410' }}>8&nbsp;lb in 6&nbsp;weeks</b> — without drama.
      </div>
    </div>

    {/* HERO */}
    <MockPhone scale={0.95} offsetY={860} z={5}>
      <ProgressTrendUI />
    </MockPhone>

    {/* big −8.2 lb callout pointing at endpoint */}
    <div style={{ position: 'absolute', top: 1800, right: 90, zIndex: 10, transform: 'rotate(-3deg)' }}>
      <div style={{
        padding: '28px 44px', borderRadius: 36,
        background: '#1A1410', color: '#fff',
        fontFamily: '"Bricolage Grotesque", sans-serif',
        boxShadow: '0 30px 60px -20px rgba(20,8,2,0.5)',
        textAlign: 'center',
      }}>
        <div style={{ fontSize: 28, color: '#FF8A3D', fontFamily: '"Manrope", sans-serif', fontWeight: 700, letterSpacing: '0.16em', textTransform: 'uppercase' }}>6 weeks</div>
        <div style={{ fontSize: 130, fontWeight: 800, letterSpacing: '-0.04em', lineHeight: 1, marginTop: 8, color: '#FF8A3D' }}>−8.2&nbsp;lb</div>
      </div>
      {/* tail arrow toward endpoint */}
      <svg style={{ position: 'absolute', bottom: -60, left: 60 }} width="180" height="120" viewBox="0 0 180 120" fill="none">
        <path d="M 20 10 C 30 60, 70 90, 160 100" stroke="#1A1410" strokeWidth="6" strokeLinecap="round" fill="none" />
        <path d="M 130 80 L 162 102 L 138 110" stroke="#1A1410" strokeWidth="6" strokeLinecap="round" strokeLinejoin="round" fill="none" />
      </svg>
    </div>
  </div>
);

// ============================================================ EXPORT

Object.assign(window, {
  Screen_PickAnyWay, Screen_AIReads, Screen_Widgets,
  Screen_Coach, Screen_Protein, Screen_Progress,
  SCREENSHOT_W: W, SCREENSHOT_H: H,
});

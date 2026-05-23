const { DesignCanvas, DCSection, DCArtboard } = window;

function App() {
  return (
    <DesignCanvas title="Voidpen · App Store screenshots" subtitle="iPhone 6.5″ · 1242 × 2688 px · 6 frames">
      <DCSection id="appstore" title="App Store · 6.5″">
        <DCArtboard id="s1" label="01 · Snap. Speak. Scan. Type." width={SCREENSHOT_W} height={SCREENSHOT_H}><Screen_PickAnyWay /></DCArtboard>
        <DCArtboard id="s2" label="02 · AI reads your plate"      width={SCREENSHOT_W} height={SCREENSHOT_H}><Screen_AIReads /></DCArtboard>
        <DCArtboard id="s3" label="03 · Glance at your macros"    width={SCREENSHOT_W} height={SCREENSHOT_H}><Screen_Widgets /></DCArtboard>
        <DCArtboard id="s4" label="04 · Chat with your AI coach"  width={SCREENSHOT_W} height={SCREENSHOT_H}><Screen_Coach /></DCArtboard>
        <DCArtboard id="s5" label="05 · Hit your protein goal"    width={SCREENSHOT_W} height={SCREENSHOT_H}><Screen_Protein /></DCArtboard>
        <DCArtboard id="s6" label="06 · Watch your progress trend" width={SCREENSHOT_W} height={SCREENSHOT_H}><Screen_Progress /></DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);

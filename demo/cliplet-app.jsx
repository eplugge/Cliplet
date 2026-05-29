/* global React, ReactDOM, MenuBar, EditorWindow, ChatWindow, Popover, QuickLook, Pointer, KeyHint, Caption */
const { useState, useRef, useEffect } = React;

/* ---------------- clip history data ---------------- */
const DATA = [
  { id: "c1", kind: "url",   preview: "https://github.com/eplugge/Cliplet" },
  { id: "c2", kind: "text",  preview: "brew install --cask eplugge/tap/cliplet" },
  { id: "c3", kind: "text",  preview: "Paste from the past." },
  { id: "c4", kind: "image", preview: "Image: Screenshot · PNG · 777.2 KB",
    qlTitle: "Screenshot.png", qlDims: "2048 × 1280", qlSize: "777.2 KB" },
  { id: "c5", kind: "file",  preview: "File: brand-logo.svg · SVG" },
  { id: "c6", kind: "text",  preview: 'git commit -m "ship the menu-bar clip history"' },
  { id: "c7", kind: "image", preview: "Image: logo@2x · PNG · 88.1 KB",
    qlTitle: "logo@2x.png", qlDims: "512 × 512", qlSize: "88.1 KB" },
  { id: "c8", kind: "text",  preview: "eelco@cliplet.app" },
  { id: "c9", kind: "url",   preview: "https://news.ycombinator.com" },
  { id: "c10", kind: "text", preview: "#0A5AD0" },
];
const cloneData = () => DATA.map((c) => ({ ...c, pinned: false }));

/* ---------------- frozen-frame presets (for deterministic capture) ---------------- */
function presetState(name) {
  const img = DATA.find((c) => c.preview.includes("Screenshot"));
  const brew = DATA.find((c) => c.preview.includes("brew install"));
  const junk = DATA.find((c) => c.preview.includes("#0A5AD0"));
  const base = { clipActive: true, popoverOpen: true, pointerHidden: true, capShow: false, keyShow: false };
  switch (name) {
    case "popover":
    case "hero": return { ...base, selectedId: img.id };
    case "filter": return { ...base, search: "screen", selectedId: img.id };
    case "quicklook": return { ...base, search: "screen", selectedId: img.id, quickLookId: img.id };
    case "pin": {
      const arr = cloneData();
      const i = arr.findIndex((c) => c.id === brew.id);
      const [it] = arr.splice(i, 1); it.pinned = true; arr.unshift(it);
      return { ...base, clips: arr, selectedId: brew.id };
    }
    case "delete": return { ...base, selectedId: junk.id, deleteConfirmId: junk.id };
    case "paste": return { clipActive: false, popoverOpen: false, pointerHidden: true, capShow: false, chatPasted: true, chatSent: true, sendReady: true };
    default: return {};
  }
}
const _params = new URLSearchParams(location.search);
const _pathMatch = location.pathname.match(/_frames\/([a-z]+)-(dark|light)\.html/i);
const FRAME = (() => {
  const f = (typeof window !== "undefined" && window.__FRAME) || _params.get("frame") || (_pathMatch && _pathMatch[1]);
  return (!f || f === "live") ? null : f;
})();
const FTHEME = (typeof window !== "undefined" && window.__THEME) || _params.get("theme") || (_pathMatch && _pathMatch[2]) || "dark";
try { localStorage.removeItem("cliplet_frame"); localStorage.removeItem("cliplet_theme"); } catch (e) {}

/* ---------------- layout ---------------- */
const POPOVER_LEFT = 760;   // clip icon center 980 − 220
const POPOVER_TOP = 34;

function matches(clip, q) {
  if (!q) return true;
  return clip.preview.toLowerCase().includes(q.toLowerCase());
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function App() {
  const [s, setS] = useState(() => ({
    theme: FTHEME,
    clock: "Thu 29 May  9:41",
    clipActive: false,
    popoverOpen: false,
    search: "",
    clips: cloneData(),
    selectedId: null,
    quickLookId: null,
    deleteConfirmId: null,
    flashId: null,
    footerHot: null,
    chatPasted: false,
    chatSent: false,
    sendReady: false,
    curX: 360, curY: 470, curDur: 600, clicking: false, down: false, pointerHidden: false,
    keyLabel: "", keyShow: false,
    capScene: "", capText: "", capShow: false,
    ...(FRAME ? presetState(FRAME) : {}),
  }));

  const canvasRef = useRef(null);
  const setRef = useRef(setS);
  const ctrl = useRef({ paused: false, speed: 1, restart: false, frozen: false, startAt: null, alive: true });

  const merge = (patch) => setRef.current((prev) => ({ ...prev, ...patch }));

  /* center of a hit element in canvas (1280×800) coordinates */
  function center(sel) {
    const cv = canvasRef.current;
    if (!cv) return null;
    const el = cv.querySelector(sel);
    if (!el) return null;
    const cr = cv.getBoundingClientRect();
    const r = el.getBoundingClientRect();
    const scale = cr.width / 1280;
    return { x: (r.left + r.width / 2 - cr.left) / scale, y: (r.top + r.height / 2 - cr.top) / scale };
  }
  const tip = (p) => (p ? { x: p.x - 4, y: p.y - 2 } : null);

  useEffect(() => {
    const c = ctrl.current;
    c.alive = true;

    // Frozen-frame capture mode: render one static preset, no animation loop.
    if (FRAME) {
      document.body.classList.add("capture");
      window.__demo = {
        live() { localStorage.setItem("cliplet_frame", "live"); location.reload(); },
        setTheme(t) { merge({ theme: t }); },
      };
      return () => { c.alive = false; };
    }

    async function wait(ms) {
      let rem = ms;
      while (rem > 0) {
        if (!c.alive) throw "dead";
        if (c.restart) throw "restart";
        if (c.paused) { await sleep(60); continue; }
        const step = Math.min(50, rem);
        await sleep(step / c.speed);
        rem -= step;
      }
    }
    async function moveTo(target, dur = 650) {
      const p = typeof target === "function" ? target() : target;
      const t = tip(p);
      if (t) merge({ curX: t.x, curY: t.y, curDur: dur });
      await wait(dur + 40);
    }
    async function click() {
      merge({ down: true });
      await wait(110);
      merge({ down: false, clicking: true });
      await wait(420);
      merge({ clicking: false });
    }
    async function key(label) {
      merge({ keyLabel: label, keyShow: true });
      await wait(560);
      merge({ keyShow: false });
      await wait(140);
    }
    async function caption(scene, text) {
      merge({ capShow: false });
      await wait(190);
      merge({ capScene: scene, capText: text, capShow: true });
      await wait(110);
    }
    async function type(text, per = 95) {
      let cur = "";
      for (const ch of text) { cur += ch; merge({ search: cur }); await wait(per); }
    }
    function find(sub) { return DATA.find((c) => c.preview.includes(sub)); }

    function resetA() {
      merge({
        clipActive: false, popoverOpen: false, search: "", clips: cloneData(),
        selectedId: null, quickLookId: null, deleteConfirmId: null, flashId: null, footerHot: null,
        chatPasted: false, chatSent: false, sendReady: false, keyShow: false,
        curX: 360, curY: 470, curDur: 700, pointerHidden: false,
      });
    }
    function resetB() {
      merge({
        clipActive: false, popoverOpen: false, search: "", clips: cloneData(),
        selectedId: null, quickLookId: null, deleteConfirmId: null, flashId: null, footerHot: null,
        keyShow: false, curX: 360, curY: 470, curDur: 700, pointerHidden: false,
      });
    }

    /* ----------- SCENE 1: search → quick look → paste ----------- */
    async function sceneA() {
      await caption("Scene 1 / 2", "Everything you copy — kept and searchable");
      await wait(900);
      await caption("Scene 1 / 2", "Click the menu-bar icon");
      await moveTo(() => tip(center('[data-hit="clip-icon"]')), 800);
      await wait(120);
      await click();
      merge({ clipActive: true, popoverOpen: true, selectedId: DATA[0].id });
      await wait(750);

      await caption("Scene 1 / 2", "Type to filter");
      await moveTo(() => tip(center('[data-hit="search"]')), 520);
      await click();
      await type("screen", 100);
      await wait(450);

      const img = find("Screenshot");
      merge({ selectedId: img.id });
      await wait(550);

      await caption("Scene 1 / 2", "Space → Quick Look preview");
      await moveTo(() => tip(center('[data-hit="row-' + img.id + '"]')), 420);
      await key("space");
      merge({ quickLookId: img.id });
      await wait(1900);
      merge({ quickLookId: null });
      await wait(350);

      await caption("Scene 1 / 2", "Click to copy it back");
      await moveTo(() => tip(center('[data-hit="row-' + img.id + '"]')), 380);
      await click();
      merge({ popoverOpen: false, clipActive: false, search: "" });
      await wait(550);

      await caption("Scene 1 / 2", "Paste anywhere — ⌘V");
      await moveTo(() => tip(center('[data-hit="chat-field"]')), 800);
      await click();
      await wait(180);
      await key("⌘V");
      merge({ chatPasted: true, sendReady: true });
      await wait(750);
      await moveTo(() => tip(center('[data-hit="send"]')), 480);
      await click();
      merge({ chatSent: true });
      await wait(1900);
    }

    /* ----------- SCENE 2: pin + delete ----------- */
    async function sceneB() {
      await caption("Scene 2 / 2", "Open Cliplet");
      await moveTo(() => tip(center('[data-hit="clip-icon"]')), 800);
      await wait(100);
      await click();
      merge({ clipActive: true, popoverOpen: true, selectedId: DATA[0].id });
      await wait(700);

      await caption("Scene 2 / 2", "Pin the clips you reuse");
      const brew = find("brew install");
      await moveTo(() => tip(center('[data-hit="row-' + brew.id + '"]')), 520);
      merge({ selectedId: brew.id });
      await wait(450);
      // pin → jump to top, flash
      setRef.current((prev) => {
        const arr = prev.clips.map((c) => ({ ...c }));
        const i = arr.findIndex((c) => c.id === brew.id);
        const [it] = arr.splice(i, 1);
        it.pinned = true;
        arr.unshift(it);
        return { ...prev, clips: arr, selectedId: brew.id, flashId: brew.id };
      });
      await wait(650);
      merge({ flashId: null });
      await wait(700);

      await caption("Scene 2 / 2", "Delete what you don’t — ⌦ twice");
      const junk = find("#0A5AD0");
      merge({ selectedId: junk.id });
      await moveTo(() => tip(center('[data-hit="row-' + junk.id + '"]')), 480);
      await wait(280);
      await key("⌦");
      merge({ deleteConfirmId: junk.id });
      await wait(850);
      await key("⌦");
      setRef.current((prev) => ({ ...prev, clips: prev.clips.filter((c) => c.id !== junk.id), deleteConfirmId: null, selectedId: prev.clips[0]?.id }));
      await wait(950);

      await caption("Scene 2 / 2", "Esc to close");
      await key("esc");
      merge({ popoverOpen: false, clipActive: false });
      await wait(1300);
    }

    async function main() {
      // small initial delay so layout settles
      await sleep(250);
      while (c.alive) {
        if (c.frozen) { await sleep(120); continue; }
        const order = c.startAt === "B" ? ["B", "A"] : ["A", "B"];
        c.startAt = null;
        try {
          for (const sc of order) {
            if (c.frozen) break;
            if (sc === "A") { resetA(); await sceneA(); }
            else { resetB(); await sceneB(); }
          }
        } catch (e) {
          if (e !== "restart" && e !== "dead") console.error(e);
        }
        c.restart = false;
      }
    }
    main();

    /* ---------------- capture / control API ---------------- */
    function applyPreset(name) {
      const base = {
        clipActive: false, popoverOpen: false, search: "", clips: cloneData(),
        selectedId: null, quickLookId: null, deleteConfirmId: null, flashId: null, footerHot: null,
        chatPasted: false, chatSent: false, sendReady: false, keyShow: false, capShow: false, pointerHidden: true,
      };
      const img = DATA.find((c2) => c2.preview.includes("Screenshot"));
      const brew = DATA.find((c2) => c2.preview.includes("brew install"));
      const junk = DATA.find((c2) => c2.preview.includes("#0A5AD0"));
      if (name === "popover") merge({ ...base, clipActive: true, popoverOpen: true, selectedId: img.id });
      else if (name === "filter") merge({ ...base, clipActive: true, popoverOpen: true, search: "screen", selectedId: img.id });
      else if (name === "quicklook") merge({ ...base, clipActive: true, popoverOpen: true, search: "screen", selectedId: img.id, quickLookId: img.id });
      else if (name === "pin") {
        const arr = cloneData();
        const i = arr.findIndex((c2) => c2.id === brew.id);
        const [it] = arr.splice(i, 1); it.pinned = true; arr.unshift(it);
        merge({ ...base, clipActive: true, popoverOpen: true, clips: arr, selectedId: brew.id });
      } else if (name === "delete") merge({ ...base, clipActive: true, popoverOpen: true, selectedId: junk.id, deleteConfirmId: junk.id });
      else if (name === "paste") merge({ ...base, chatPasted: true, chatSent: true, sendReady: true });
      else if (name === "hero") merge({ ...base, clipActive: true, popoverOpen: true, selectedId: img.id });
    }

    window.__demo = {
      pause() { c.paused = true; },
      play() { c.paused = false; c.frozen = false; },
      restart() { c.startAt = "A"; c.frozen = false; c.paused = false; c.restart = true; },
      scene(which) { c.startAt = which; c.frozen = false; c.paused = false; c.restart = true; },
      setTheme(t) { merge({ theme: t }); },
      setSpeed(v) { c.speed = v; },
      freeze(name, theme) { c.frozen = true; c.restart = true; if (theme) merge({ theme }); setTimeout(() => applyPreset(name), 40); },
      thaw() { c.frozen = false; c.paused = false; c.restart = true; merge({ pointerHidden: false }); },
      hideChrome(v) { document.body.classList.toggle("capture", !!v); },
    };

    return () => { c.alive = false; };
  }, []);

  const filtered = s.clips.filter((c) => matches(c, s.search));
  // In capture (FRAME) mode, only mount overlays when active so a stale closed
  // popover can't render. In live mode keep them mounted for fade transitions.
  const mountPopover = FRAME ? s.popoverOpen : true;
  const mountQuickLook = FRAME ? !!s.quickLookId : true;

  return (
    <div className="canvas" data-theme={s.theme} ref={canvasRef}>
      <div className="wallpaper" />
      <EditorWindow />
      <ChatWindow pasted={s.chatPasted} sent={s.chatSent} sendReady={s.sendReady} />
      <MenuBar clipActive={s.clipActive} clock={s.clock} />

      {mountPopover && (
        <div className="popover-layer">
          <Popover
            open={s.popoverOpen}
            left={POPOVER_LEFT}
            top={POPOVER_TOP}
            clips={filtered}
            search={s.search}
            selectedId={s.selectedId}
            deleteConfirmId={s.deleteConfirmId}
            flashId={s.flashId}
            footerHot={s.footerHot}
          />
        </div>
      )}

      {mountQuickLook && <QuickLook show={!!s.quickLookId} clip={DATA.find((c) => c.id === s.quickLookId)} />}

      <Caption show={s.capShow} scene={s.capScene} text={s.capText} />
      <KeyHint show={s.keyShow} label={s.keyLabel} />
      <Pointer x={s.curX} y={s.curY} dur={s.curDur} clicking={s.clicking} down={s.down} hidden={s.pointerHidden} />
    </div>
  );
}

/* ---------------- scaling + controls ---------------- */
function Root() {
  const [scale, setScale] = useState(1);
  const [theme, setTheme] = useState("dark");
  const [paused, setPaused] = useState(false);
  const [speed, setSpeed] = useState(1);

  useEffect(() => {
    const fit = () => {
      const sc = Math.min(window.innerWidth / 1280, (window.innerHeight - 70) / 800);
      setScale(sc);
    };
    fit();
    window.addEventListener("resize", fit);
    return () => window.removeEventListener("resize", fit);
  }, []);

  return (
    <React.Fragment>
      <div className="stage">
        <div style={{ transform: `scale(${scale})`, transformOrigin: "center center" }}>
          <App />
        </div>
      </div>
      <div className="controls">
        <button onClick={() => { window.__demo.play(); setPaused(false); }} className={!paused ? "active" : ""}>▶︎ Play</button>
        <button onClick={() => { window.__demo.pause(); setPaused(true); }} className={paused ? "active" : ""}>❚❚ Pause</button>
        <button onClick={() => window.__demo.restart()}>↺ Restart</button>
        <span className="ctl-sep" />
        <button onClick={() => window.__demo.scene("A")}>Scene 1</button>
        <button onClick={() => window.__demo.scene("B")}>Scene 2</button>
        <span className="ctl-sep" />
        <span className="ctl-label">Theme</span>
        <button onClick={() => { window.__demo.setTheme("dark"); setTheme("dark"); }} className={theme === "dark" ? "active" : ""}>Dark</button>
        <button onClick={() => { window.__demo.setTheme("light"); setTheme("light"); }} className={theme === "light" ? "active" : ""}>Light</button>
        <span className="ctl-sep" />
        <span className="ctl-label">Speed</span>
        {[0.5, 1, 1.5].map((v) => (
          <button key={v} onClick={() => { window.__demo.setSpeed(v); setSpeed(v); }} className={speed === v ? "active" : ""}>{v}×</button>
        ))}
      </div>
    </React.Fragment>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<Root />);

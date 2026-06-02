/* global React, ReactDOM, MenuBar, EditorWindow, ChatWindow, Popover, CtxMenu, QuickLook, EditModal, ConfirmDialog, SharePane, Pointer, KeyHint, Caption */
const { useState, useRef, useEffect } = React;

/* ---------------- clip history data ---------------- */
const DATA = [
  { id: "c1", kind: "url",   preview: "https://github.com/eplugge/Cliplet" },
  { id: "c2", kind: "text",  preview: "brew install --cask eplugge/tap/cliplet" },
  { id: "c3", kind: "text",  preview: "AKIA4FJ2X9QZ7TKLMN3P" },
  { id: "c4", kind: "image", preview: "Image: Screenshot · PNG · 777.2 KB",
    qlTitle: "Screenshot.png", qlDims: "2048 × 1280", qlSize: "777.2 KB" },
  { id: "c5", kind: "text",  preview: "Sept-Maple-Otter-92!", alias: "1Password", maskMode: "hidden" },
  { id: "c6", kind: "text",  preview: 'git commit -m "ship blur + temp sessions"' },
  { id: "c7", kind: "file",  preview: "File: brand-logo.svg · SVG" },
  { id: "c8", kind: "text",  preview: "eelco@cliplet.app" },
  { id: "c9", kind: "url",   preview: "https://news.ycombinator.com" },
  { id: "c10", kind: "text", preview: "#0A5AD0" },
];
const REVEAL_LEAD = 4, REVEAL_TRAIL = 4;
const cloneData = () => DATA.map((c) => ({
  ...c, pinned: false, ephemeral: false, revealed: false,
  maskMode: c.maskMode || "none", alias: c.alias || "",
}));

/* ephemeral clips captured during a temporary session */
const SESSION_CLIPS = [
  { id: "s1", kind: "text", preview: "TOTP 4471 92", ephemeral: true, maskMode: "none", alias: "", pinned: false, revealed: false },
  { id: "s2", kind: "url",  preview: "https://staging.acme.dev/?token=tmp", ephemeral: true, maskMode: "none", alias: "", pinned: false, revealed: false },
];

function placeholderFor(paused, sessionActive) {
  if (sessionActive) return "Temporary session — clips clear when you end it";
  if (paused) return "Clipboard tracking paused";
  return "Type to filter. Click to copy.";
}

/* ---------------- command / context menu item sets ---------------- */
const COMMAND_ITEMS = [
  { label: "Pause Cliplet" },
  { label: "Start Temporary Session" },
  { sep: true },
  { label: "Clear" },
  { sep: true },
  { label: "Preferences…", key: "⌘," },
  { label: "Quit Cliplet", key: "⌘Q" },
];
const ROW_CTX_ITEMS = [
  { label: "Preview", key: "Space" },
  { label: "Blur" },
  { label: "Edit…" },
  { label: "Pin" },
  { sep: true },
  { label: "Delete", destructive: true },
];

/* ---------------- frozen-frame presets (deterministic capture) ---------------- */
function presetState(name) {
  const arr = cloneData();
  const set = (id, patch) => { const c = arr.find((x) => x.id === id); if (c) Object.assign(c, patch); };
  const img = arr.find((c) => c.preview.includes("Screenshot"));
  const base = {
    clipActive: true, popoverOpen: true, pointerHidden: true, capShow: false, keyShow: false,
    iconState: "normal", recording: false, paused: false, sessionActive: false,
    search: "", quickLookId: null, deleteConfirmId: null, flashId: null, footerHot: null,
    ctxMenu: null, editModal: null, dialog: null, sharePane: false,
    chatPasted: false, chatSent: false, sendReady: false,
    cam: CAM.pop, camDur: 0, hudScrim: false,
  };
  switch (name) {
    case "hero": {
      set("c3", { maskMode: "blurred", alias: "AWS key" });
      return { ...base, clips: arr, selectedId: img.id };
    }
    case "secrets": {
      set("c3", { maskMode: "blurred", alias: "AWS key" });
      return { ...base, clips: arr, selectedId: "c3" };
    }
    case "editing": {
      set("c3", { maskMode: "blurred", alias: "AWS key" });
      return { ...base, clips: arr, selectedId: "c3", cam: CAM.edit,
        editModal: { show: true, preview: "AKIA4FJ2X9QZ7TKLMN3P", alias: "AWS key", aliasFocus: false, mode: "blurred", saveHot: true, cancelHot: false } };
    }
    case "pause":
      return { ...base, clips: arr, paused: true, iconState: "paused", selectedId: arr[0].id };
    case "session": {
      const withEph = [...SESSION_CLIPS.map((c) => ({ ...c })), ...arr];
      return { ...base, clips: withEph, sessionActive: true, iconState: "session", selectedId: "s1", cam: CAM.popTall };
    }
    case "share": {
      set("c3", { maskMode: "blurred", alias: "AWS key" });
      return { ...base, clips: arr, recording: true, selectedId: "c5", sharePane: true, cam: CAM.share };
    }
    default: return { ...base, clips: arr };
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
const POPOVER_LEFT = 760;
const POPOVER_TOP = 34;

/* cinematic camera presets (canvas 1280×800 coords): center + zoom */
const CAM = {
  full: { cx: 640, cy: 400, z: 1 },
  pop: { cx: 1004, cy: 300, z: 1.5 },
  popTall: { cx: 1004, cy: 320, z: 1.42 },
  edit: { cx: 640, cy: 392, z: 1.66 },
  chat: { cx: 989, cy: 556, z: 1.52 },
  dialog: { cx: 640, cy: 432, z: 1.78 },
  ql: { cx: 640, cy: 400, z: 1.4 },
  share: { cx: 612, cy: 330, z: 1.12 },
  icon: { cx: 1080, cy: 150, z: 1.6 },
};

function matches(clip, q) {
  if (!q) return true;
  const hay = (clip.preview + " " + (clip.alias || "")).toLowerCase();
  return hay.includes(q.toLowerCase());
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
    iconState: "normal",
    recording: false,
    paused: false,
    sessionActive: false,
    ctxMenu: null,
    editModal: null,
    dialog: null,
    sharePane: false,
    curX: 360, curY: 470, curDur: 600, clicking: false, down: false, pointerHidden: false, pointerRight: false,
    keyLabel: "", keyShow: false,
    capStep: "", capText: "", capShow: false,
    cam: null, camDur: 800, hudScrim: false,
    ...(FRAME ? presetState(FRAME) : {}),
  }));

  const canvasRef = useRef(null);
  const setRef = useRef(setS);
  const ctrl = useRef({ paused: false, speed: 1, restart: false, frozen: false, startAt: null, alive: true });

  const merge = (patch) => setRef.current((prev) => ({ ...prev, ...patch }));

  function center(sel) {
    const cv = canvasRef.current;
    if (!cv) return null;
    const el = cv.querySelector(sel);
    if (!el) return null;
    const cr = cv.getBoundingClientRect();
    const r = el.getBoundingClientRect();
    const fit = cr.width / 1280;
    const cam = ctrl.current.cam || { cx: 640, cy: 400, z: 1 };
    const z = cam.z, tx = 640 - cam.cx * z, ty = 400 - cam.cy * z;
    // canvas-space (camera already applied), then invert camera → logical coords
    const sx = (r.left + r.width / 2 - cr.left) / fit;
    const sy = (r.top + r.height / 2 - cr.top) / fit;
    return { x: (sx - tx) / z, y: (sy - ty) / z };
  }
  const tip = (p) => (p ? { x: p.x - 4, y: p.y - 2 } : null);

  useEffect(() => {
    const c = ctrl.current;
    c.alive = true;

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
    async function move(x, y, dur = 600) { merge({ curX: x, curY: y, curDur: dur }); await wait(dur + 40); }
    async function click() {
      merge({ down: true });
      await wait(110);
      merge({ down: false, clicking: true });
      await wait(420);
      merge({ clicking: false });
    }
    async function rightClick() {
      merge({ pointerRight: true, down: true });
      await wait(150);
      merge({ down: false, clicking: true });
      await wait(420);
      merge({ clicking: false });
      await wait(120);
      merge({ pointerRight: false });
    }
    async function key(label) {
      merge({ keyLabel: label, keyShow: true });
      await wait(560);
      merge({ keyShow: false });
      await wait(140);
    }
    async function caption(text) {
      merge({ capShow: false });
      await wait(220);
      merge({ capText: text, capShow: true, hudScrim: true });
      await wait(140);
    }
    function setStep(label) { merge({ capStep: label }); }
    async function focus(cam, dur = 900) {
      ctrl.current.cam = cam;
      merge({ cam: cam, camDur: dur });
      await wait(Math.min(dur, 720));
    }
    async function type(text, per = 95) {
      let cur = "";
      for (const ch of text) { cur += ch; merge({ search: cur }); await wait(per); }
    }
    function find(sub) { return DATA.find((cl) => cl.preview.includes(sub)); }

    function resetAll(extra) {
      ctrl.current.cam = CAM.full;
      merge({
        clipActive: false, popoverOpen: false, search: "", clips: cloneData(),
        selectedId: null, quickLookId: null, deleteConfirmId: null, flashId: null, footerHot: null,
        chatPasted: false, chatSent: false, sendReady: false,
        iconState: "normal", recording: false, paused: false, sessionActive: false,
        ctxMenu: null, editModal: null, dialog: null, sharePane: false,
        keyShow: false, curX: 360, curY: 470, curDur: 700, pointerHidden: false, pointerRight: false,
        cam: CAM.full, camDur: 900, hudScrim: false,
        ...(extra || {}),
      });
    }

    /* ----------- SCENE 1: capture → search → quick look → paste ----------- */
    async function sceneCapture() {
      resetAll();
      setStep("Clipboard history");
      await focus(CAM.full, 100);
      await caption("Everything you copy — kept and searchable");
      await wait(1100);

      await caption("Click the menu-bar icon");
      await focus(CAM.icon, 850);
      await moveTo(() => tip(center('[data-hit="clip-icon"]')), 650);
      await wait(100); await click();
      merge({ clipActive: true, popoverOpen: true, selectedId: DATA[0].id });
      await focus(CAM.pop, 850);
      await wait(700);

      await caption("Type to filter — by contents or alias");
      await moveTo(() => tip(center('[data-hit="search"]')), 480);
      await click();
      await type("screen", 105);
      await wait(450);
      const img = find("Screenshot");
      merge({ selectedId: img.id });
      await wait(650);

      await caption("Press Space for a Quick Look");
      await moveTo(() => tip(center('[data-hit="row-' + img.id + '"]')), 380);
      await key("space");
      await focus(CAM.ql, 600);
      merge({ quickLookId: img.id });
      await wait(1900);
      merge({ quickLookId: null });
      await focus(CAM.pop, 600);
      await wait(380);

      await caption("Click to copy it back");
      await moveTo(() => tip(center('[data-hit="row-' + img.id + '"]')), 360);
      await click();
      merge({ popoverOpen: false, clipActive: false, search: "" });
      await wait(450);

      await caption("Paste anywhere — ⌘V");
      await focus(CAM.chat, 850);
      await moveTo(() => tip(center('[data-hit="chat-field"]')), 700);
      await click();
      await wait(180);
      await key("⌘V");
      merge({ chatPasted: true, sendReady: true });
      await wait(750);
      await moveTo(() => tip(center('[data-hit="send"]')), 440);
      await click();
      merge({ chatSent: true });
      await wait(1900);
    }

    /* ----------- SCENE 2: blur / mask sensitive clips ----------- */
    async function sceneBlur() {
      resetAll();
      setStep("Blur & hide");
      await caption("Copied a secret? Mask it in a click");
      await focus(CAM.icon, 100);
      await moveTo(() => tip(center('[data-hit="clip-icon"]')), 650);
      await wait(100); await click();
      merge({ clipActive: true, popoverOpen: true, selectedId: "c3" });
      await focus(CAM.pop, 850);
      await wait(700);

      await caption("Some clips are already hidden behind ••••••");
      merge({ selectedId: "c5" });
      await wait(1700);

      await caption("Right-click any clip, then Edit…");
      await moveTo(() => tip(center('[data-hit="row-c3"]')), 480);
      merge({ selectedId: "c3" });
      await wait(250);
      await rightClick();
      merge({ ctxMenu: { left: 980, top: 112, items: ROW_CTX_ITEMS, hot: -1 } });
      await wait(550);
      await move(1058, 173, 420);
      merge({ ctxMenu: { left: 980, top: 112, items: ROW_CTX_ITEMS, hot: 2 } });
      await wait(480);
      await click();
      merge({ ctxMenu: null, editModal: { show: true, preview: "AKIA4FJ2X9QZ7TKLMN3P", alias: "", aliasFocus: true, mode: "none", saveHot: false, cancelHot: false } });
      await focus(CAM.edit, 700);
      await wait(650);

      await caption("Give it an alias…");
      let a = "";
      for (const ch of "AWS key") { a += ch; setRef.current((prev) => ({ ...prev, editModal: { ...prev.editModal, alias: a } })); await wait(95); }
      await wait(500);

      await caption("…then set the display to Blur");
      setRef.current((prev) => ({ ...prev, editModal: { ...prev.editModal, aliasFocus: false, mode: "blurred" } }));
      await wait(900);
      setRef.current((prev) => ({ ...prev, editModal: { ...prev.editModal, saveHot: true } }));
      await move(740, 470, 360);
      await wait(160); await click();
      setRef.current((prev) => ({
        ...prev, editModal: null,
        clips: prev.clips.map((cl) => cl.id === "c3" ? { ...cl, maskMode: "blurred", alias: "AWS key" } : cl),
        flashId: "c3",
      }));
      await focus(CAM.pop, 700);
      await wait(700); merge({ flashId: null });
      await wait(650);

      await caption("Reveal it only when you need it");
      merge({ selectedId: "c3" });
      await moveTo(() => tip(center('[data-hit="row-c3"]')), 380);
      await key("⌥-click");
      setRef.current((prev) => ({ ...prev, clips: prev.clips.map((cl) => cl.id === "c3" ? { ...cl, revealed: true } : cl) }));
      await wait(1700);
      setRef.current((prev) => ({ ...prev, clips: prev.clips.map((cl) => cl.id === "c3" ? { ...cl, revealed: false } : cl) }));
      await wait(950);
      await key("esc");
      merge({ popoverOpen: false, clipActive: false });
      await wait(1100);
    }

    /* ----------- SCENE 3: pause capture (right-click command menu) ----------- */
    async function scenePause() {
      resetAll();
      setStep("Pause capture");
      await caption("Right-click the icon for quick commands");
      await focus(CAM.icon, 100);
      await moveTo(() => tip(center('[data-hit="clip-icon"]')), 650);
      await wait(150);
      await rightClick();
      merge({ clipActive: true, ctxMenu: { left: 800, top: 30, items: COMMAND_ITEMS, hot: -1 } });
      await wait(600);
      await move(880, 47, 380);
      merge({ ctxMenu: { left: 800, top: 30, items: COMMAND_ITEMS, hot: 0 } });
      await wait(550);
      await click();
      merge({ ctxMenu: null, paused: true, iconState: "paused" });
      await wait(450);

      await caption("Capture paused — the icon shows it");
      await moveTo(() => tip(center('[data-hit="clip-icon"]')), 550);
      await wait(1900);

      await caption("Open Cliplet — it says it’s paused");
      await click();
      setRef.current((prev) => ({ ...prev, popoverOpen: true, selectedId: prev.clips[0].id }));
      await focus(CAM.pop, 800);
      await wait(2000);

      await caption("Resume the moment you’re ready");
      await moveTo(() => tip(center('[data-hit="foot-pause"]')), 560);
      merge({ footerHot: "pause" });
      await wait(280); await click();
      merge({ footerHot: null, paused: false, iconState: "normal", popoverOpen: false, clipActive: false });
      await wait(1300);
    }

    /* ----------- SCENE 4: temporary session ----------- */
    async function sceneSession() {
      resetAll();
      setStep("Temporary session");
      await caption("Working on something throwaway?");
      await focus(CAM.icon, 100);
      await moveTo(() => tip(center('[data-hit="clip-icon"]')), 650);
      await wait(100); await click();
      merge({ clipActive: true, popoverOpen: true, selectedId: DATA[0].id });
      await focus(CAM.popTall, 850);
      await wait(650);

      await caption("Start a temporary session");
      await moveTo(() => tip(center('[data-hit="foot-session"]')), 520);
      merge({ footerHot: "session" });
      await wait(280); await click();
      merge({ footerHot: null, sessionActive: true, iconState: "session" });
      await wait(1200);

      await caption("New clips are marked with an hourglass");
      setRef.current((prev) => ({ ...prev, clips: [{ ...SESSION_CLIPS[0] }, ...prev.clips], selectedId: "s1", flashId: "s1" }));
      await wait(700); merge({ flashId: null });
      await wait(600);
      setRef.current((prev) => ({ ...prev, clips: [{ ...SESSION_CLIPS[1] }, ...prev.clips], selectedId: "s2", flashId: "s2" }));
      await wait(700); merge({ flashId: null });
      await wait(1400);

      await caption("End the session…");
      await moveTo(() => tip(center('[data-hit="foot-session"]')), 520);
      merge({ footerHot: "session" });
      await wait(280); await click();
      merge({ footerHot: null, dialog: { show: true, count: 2, dontAsk: false, keepHot: false, discardHot: false } });
      await focus(CAM.dialog, 700);
      await wait(950);

      await caption("…and those clips are gone for good");
      setRef.current((prev) => ({ ...prev, dialog: { ...prev.dialog, discardHot: true } }));
      await move(700, 470, 360);
      await wait(220); await click();
      setRef.current((prev) => ({
        ...prev, dialog: null, sessionActive: false, iconState: "normal",
        clips: prev.clips.filter((cl) => !cl.ephemeral),
        selectedId: "c1",
      }));
      await focus(CAM.pop, 700);
      await wait(1400);
      await key("esc");
      merge({ popoverOpen: false, clipActive: false });
      await wait(1100);
    }

    /* ----------- SCENE 5: hide during screen sharing ----------- */
    async function sceneShare() {
      resetAll({ clips: cloneData().map((cl) => cl.id === "c3" ? { ...cl, maskMode: "blurred", alias: "AWS key" } : cl) });
      setStep("Screen sharing");
      await focus(CAM.full, 100);
      await caption("Sharing your screen?");
      await wait(800);
      merge({ recording: true });
      await caption("Cliplet excludes itself from the capture");
      await wait(1000);

      await focus(CAM.icon, 800);
      await moveTo(() => tip(center('[data-hit="clip-icon"]')), 650);
      await wait(100); await click();
      merge({ clipActive: true, popoverOpen: true, selectedId: "c5" });
      await focus(CAM.pop, 800);
      await wait(1300);

      await caption("Your history is invisible to your audience");
      await focus(CAM.share, 850);
      merge({ sharePane: true });
      await wait(2900);

      merge({ pointerHidden: true });
      await wait(400);
      merge({ sharePane: false });
      await wait(400);
      merge({ popoverOpen: false, clipActive: false, recording: false });
      await wait(1100);
    }

    const SCENES = {
      capture: sceneCapture, blur: sceneBlur, pause: scenePause,
      session: sceneSession, share: sceneShare,
    };
    const ORDER = ["capture", "blur", "pause", "session", "share"];

    async function main() {
      await sleep(250);
      while (c.alive) {
        if (c.frozen) {
          if (c.frozenName) applyPreset(c.frozenName);
          await sleep(140); continue;
        }
        let order = ORDER;
        if (c.startAt && ORDER.includes(c.startAt)) {
          const i = ORDER.indexOf(c.startAt);
          order = [...ORDER.slice(i), ...ORDER.slice(0, i)];
        }
        c.startAt = null;
        c.restart = false;
        try {
          for (const name of order) {
            if (c.frozen) break;
            await SCENES[name]();
          }
        } catch (e) {
          if (e !== "restart" && e !== "dead") console.error(e);
        }
        c.restart = false;
      }
    }
    main();

    function applyPreset(name) {
      const st = presetState(name);
      const cam = name === "editing" ? CAM.edit : name === "share" ? CAM.share
        : name === "session" ? CAM.popTall : CAM.pop;
      merge({ ...st, pointerHidden: true, capShow: false, hudScrim: false, cam: cam, camDur: 0 });
    }

    window.__demo = {
      pause() { c.paused = true; },
      play() { c.paused = false; c.frozen = false; c.frozenName = null; },
      restart() { c.startAt = "capture"; c.frozen = false; c.frozenName = null; c.paused = false; c.restart = true; },
      scene(which) { c.startAt = which; c.frozen = false; c.frozenName = null; c.paused = false; c.restart = true; },
      setTheme(t) { merge({ theme: t }); },
      setSpeed(v) { c.speed = v; },
      freeze(name, theme) { c.frozen = true; c.restart = true; c.frozenName = name; if (theme) merge({ theme }); },
      thaw() { c.frozen = false; c.frozenName = null; c.paused = false; c.restart = true; merge({ pointerHidden: false }); },
      hideChrome(v) { document.body.classList.toggle("capture", !!v); },
    };

    return () => { c.alive = false; };
  }, []);

  const filtered = s.clips.filter((c) => matches(c, s.search));
  const mountPopover = FRAME ? s.popoverOpen : true;
  const mountQuickLook = FRAME ? !!s.quickLookId : true;
  const placeholder = placeholderFor(s.paused, s.sessionActive);

  const cam = s.cam;
  const z = cam ? cam.z : 1;
  const cx = cam ? cam.cx : 640, cy = cam ? cam.cy : 400;
  const worldStyle = {
    transform: "translate(" + (640 - cx * z) + "px," + (400 - cy * z) + "px) scale(" + z + ")",
    transition: "transform " + s.camDur + "ms cubic-bezier(0.4,0,0.2,1)",
  };

  return (
    <div className="canvas" data-theme={s.theme} ref={canvasRef}>
      <div className="world" style={worldStyle}>
        <div className="wallpaper" />
        <EditorWindow />
        <ChatWindow pasted={s.chatPasted} sent={s.chatSent} sendReady={s.sendReady} />
        <MenuBar clipActive={s.clipActive} clock={s.clock} iconState={s.iconState} recording={s.recording} />

        <SharePane show={s.sharePane} />

        {mountPopover && (
          <div className="popover-layer">
            <Popover
              open={s.popoverOpen}
              left={POPOVER_LEFT}
              top={POPOVER_TOP}
              clips={filtered}
              search={s.search}
              placeholder={placeholder}
              selectedId={s.selectedId}
              deleteConfirmId={s.deleteConfirmId}
              flashId={s.flashId}
              footerHot={s.footerHot}
              paused={s.paused}
              sessionActive={s.sessionActive}
              revealLead={REVEAL_LEAD}
              revealTrail={REVEAL_TRAIL}
            />
          </div>
        )}

        {s.ctxMenu && (
          <div className="menu-layer">
            <CtxMenu left={s.ctxMenu.left} top={s.ctxMenu.top} items={s.ctxMenu.items} hot={s.ctxMenu.hot} />
          </div>
        )}

        {mountQuickLook && <QuickLook show={!!s.quickLookId} clip={DATA.find((c) => c.id === s.quickLookId)} />}

        {s.editModal && <EditModal {...s.editModal} />}
        {s.dialog && <ConfirmDialog {...s.dialog} />}

        <Pointer x={s.curX} y={s.curY} dur={s.curDur} clicking={s.clicking} down={s.down} hidden={s.pointerHidden} right={s.pointerRight} z={z} />
      </div>

      <div className="hud">
        <div className={"hud-scrim" + (s.hudScrim ? " show" : "")} />
        <div className={"hud-key" + (s.keyShow ? " show" : "")}>
          <span className="kc">{s.keyLabel}</span>
        </div>
        <div className={"bigcap" + (s.capShow ? " show" : "")}>
          {s.capStep && <span className="bc-step">{s.capStep}</span>}
          <span className="bc-text">{s.capText}</span>
        </div>
      </div>
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

  const scenes = [["capture", "Capture"], ["blur", "Blur"], ["pause", "Pause"], ["session", "Session"], ["share", "Screen share"]];

  return (
    <React.Fragment>
      <div className="stage">
        <div style={{ transform: `scale(${scale})`, transformOrigin: "center center" }}>
          <App />
        </div>
      </div>
      <div className="controls">
        <button onClick={() => { window.__demo.play(); setPaused(false); }} className={!paused ? "active" : ""}>▶︎</button>
        <button onClick={() => { window.__demo.pause(); setPaused(true); }} className={paused ? "active" : ""}>❚❚</button>
        <button onClick={() => window.__demo.restart()}>↺</button>
        <span className="ctl-sep" />
        {scenes.map(([id, label]) => (
          <button key={id} onClick={() => window.__demo.scene(id)}>{label}</button>
        ))}
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

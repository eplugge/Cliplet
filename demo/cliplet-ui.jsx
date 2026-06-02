/* global React */
const { useRef } = React;

/* ---------- tiny inline icons (simple shapes only) ---------- */
function Paperclip({ size = 16 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
      stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <path d="M20 11.5l-8.1 8.1a4.6 4.6 0 0 1-6.5-6.5l8.4-8.4a3 3 0 0 1 4.3 4.3l-8.3 8.3a1.4 1.4 0 0 1-2-2l7.6-7.6" />
    </svg>
  );
}

/* paperclip with two pause bars knocked over the centre (matches ClipletIcon.pausedImage) */
function PaperclipPaused({ size = 16 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <path d="M20 11.5l-8.1 8.1a4.6 4.6 0 0 1-6.5-6.5l8.4-8.4a3 3 0 0 1 4.3 4.3l-8.3 8.3a1.4 1.4 0 0 1-2-2l7.6-7.6"
        stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
      <rect x="8.0" y="8.4" width="2.6" height="7.2" rx="1.1" fill="currentColor" stroke="var(--menubar-solid, #1b1924)" strokeWidth="1.1" />
      <rect x="12.0" y="8.4" width="2.6" height="7.2" rx="1.1" fill="currentColor" stroke="var(--menubar-solid, #1b1924)" strokeWidth="1.1" />
    </svg>
  );
}

/* paperclip wearing a spy fedora + round shades (matches ClipletIcon.sessionImage "spy") */
function PaperclipSpy({ size = 16 }) {
  const h = size * 1.4;
  return (
    <svg width={size} height={h} viewBox="0 0 24 34" fill="none" style={{ marginTop: -(h - size) }}>
      <g transform="translate(0,10)">
        <path d="M20 11.5l-8.1 8.1a4.6 4.6 0 0 1-6.5-6.5l8.4-8.4a3 3 0 0 1 4.3 4.3l-8.3 8.3a1.4 1.4 0 0 1-2-2l7.6-7.6"
          stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
      </g>
      {/* fedora */}
      <path d="M6.2 9.5 Q12 6.4 17.8 9.5 Q12 11.0 6.2 9.5 Z" fill="currentColor" />
      <path d="M8.4 9.2 L9.2 3.2 Q12 2.0 14.8 3.2 L15.6 9.2 Z" fill="currentColor" />
      <rect x="8.7" y="7.6" width="6.6" height="1.4" rx="0.4" fill="var(--menubar-solid, #1b1924)" />
      {/* round shades sitting on the clip's upper loop */}
      <g transform="translate(0,13.6)">
        <circle cx="8.7" cy="2.0" r="2.7" fill="currentColor" />
        <circle cx="15.3" cy="2.0" r="2.7" fill="currentColor" />
        <rect x="10.9" y="1.5" width="2.2" height="1.2" fill="currentColor" />
        <circle cx="8.7" cy="2.0" r="1.5" fill="var(--menubar-solid, #1b1924)" />
        <circle cx="15.3" cy="2.0" r="1.5" fill="var(--menubar-solid, #1b1924)" />
      </g>
    </svg>
  );
}

function HourglassIcon({ size = 11 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
      stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 3h12M6 21h12M7 3c0 5 4 6 5 9 1-3 5-4 5-9M7 21c0-5 4-6 5-9 1 3 5 4 5 9" />
    </svg>
  );
}

function PinIcon({ size = 11 }) {
  return (
    <svg className="pr-pin-icon" width={size} height={size} viewBox="0 0 24 24"
      fill="currentColor">
      <path d="M14.5 2.3l7.2 7.2-1.5 1.5-1 -.4-4.1 4.1.3 4.6-1.4 1.4-3.9-3.9-4.6 4.6-1.2-1.2 4.6-4.6L3.6 12l1.4-1.4 4.6.3 4.1-4.1-.4-1z" />
    </svg>
  );
}

function MbGlyphs() {
  return (
    <React.Fragment>
      <span className="mb-icon" title="Wi-Fi">
        <svg width="17" height="17" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 18.5a1.6 1.6 0 1 0 0 3.2 1.6 1.6 0 0 0 0-3.2zM5.6 13.4a9 9 0 0 1 12.8 0l-1.7 1.7a6.6 6.6 0 0 0-9.4 0l-1.7-1.7zM2.4 10.2a13.5 13.5 0 0 1 19.2 0l-1.7 1.7a11.1 11.1 0 0 0-15.8 0l-1.7-1.7z" />
        </svg>
      </span>
      <span className="mb-icon" title="Battery">
        <svg width="26" height="14" viewBox="0 0 30 14" fill="none" stroke="currentColor" strokeWidth="1.2">
          <rect x="1" y="2" width="23" height="10" rx="3" />
          <rect x="3" y="4" width="16" height="6" rx="1.5" fill="currentColor" stroke="none" />
          <path d="M26 5v4c1.2-.3 1.2-3.7 0-4z" fill="currentColor" stroke="none" />
        </svg>
      </span>
      <span className="mb-icon" title="Control Center">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round">
          <path d="M4 8h16M4 16h16" /><circle cx="9" cy="8" r="2.2" fill="currentColor" stroke="none" /><circle cx="15" cy="16" r="2.2" fill="currentColor" stroke="none" />
        </svg>
      </span>
    </React.Fragment>
  );
}

/* ---------- Menu bar ---------- */
function MenuBar({ clipActive, clock, iconState = "normal", recording = false }) {
  return (
    <div className="menubar">
      <div className="mb-left">
        <Paperclip size={15} />
        <span className="brand">Cliplet</span>
        <span className="mb-menu">File</span>
        <span className="mb-menu">Edit</span>
        <span className="mb-menu">View</span>
        <span className="mb-menu">Help</span>
      </div>
      <div className="mb-right">
        {recording && (
          <span className="mb-rec"><span className="rec-dot" />Screen Sharing</span>
        )}
        <MbGlyphs />
        <span data-hit="clip-icon"
          className={"mb-icon mb-clip"
            + (clipActive ? " active" : "")
            + (iconState === "paused" ? " paused" : "")
            + (iconState === "session" ? " session" : "")}>
          {iconState === "paused" ? <PaperclipPaused size={16} />
            : iconState === "session" ? <PaperclipSpy size={16} />
              : <Paperclip size={16} />}
        </span>
        <span className="mb-clock">{clock}</span>
      </div>
    </div>
  );
}

/* ---------- Code editor window (ambient context) ---------- */
function EditorWindow() {
  const lines = [
    [["com", "// ClipRowView.swift"]],
    [],
    [["key", "var"], ["", " body: "], ["key", "some "], ["type", "View"], ["", " {"]],
    [["", "    "], ["type", "HStack"], ["", "(spacing: "], ["num", "5"], ["", ") {"]],
    [["", "        "], ["key", "if"], ["", " clip."], ["fn", "ephemeral"], ["", " {"]],
    [["", "            "], ["type", "Image"], ["", "(systemName: "], ["str", "\"hourglass\""], ["", ")"]],
    [["", "        }"]],
    [["", "        "], ["key", "if"], ["", " clip.maskMode == ."], ["fn", "blurred"], ["", " {"]],
    [["", "            "], ["type", "Text"], ["", "(seg.middle)."], ["fn", "blur"], ["", "(radius: "], ["num", "4.5"], ["", ")"]],
    [["", "        } "], ["key", "else"], ["", " {"]],
    [["", "            "], ["type", "Text"], ["", "(clip."], ["fn", "preview"], ["", ")"]],
    [["", "        }"]],
    [["", "        "], ["key", "if"], ["", " "], ["key", "let"], ["", " alias { "], ["type", "Text"], ["", "(alias)."], ["fn", "italic"], ["", "() }"]],
    [["", "    }"]],
    [["", "}"]],
  ];
  return (
    <div className="win editor">
      <div className="win-titlebar">
        <div className="traffic"><span className="r" /><span className="y" /><span className="g" /></div>
        <span className="win-title">ClipRowView.swift — Cliplet</span>
      </div>
      <div className="editor-body">
        <div className="gutter">{lines.map((_, i) => <div key={i}>{i + 1}</div>)}</div>
        <div className="code">
          {lines.map((toks, i) => (
            <div key={i}>{toks.length ? toks.map((t, j) => (
              <span key={j} className={t[0] ? "tk-" + t[0] : ""}>{t[1]}</span>
            )) : "\u00A0"}</div>
          ))}
        </div>
      </div>
    </div>
  );
}

/* ---------- Chat / compose window (paste target) ---------- */
function ChatWindow({ pasted, sent, sendReady }) {
  return (
    <div className="win chat">
      <div className="win-titlebar">
        <div className="traffic"><span className="r" /><span className="y" /><span className="g" /></div>
        <span className="chat-name">Design — Messages</span>
      </div>
      <div className="chat-body">
        <div className="msg them">Did the new screenshot land?</div>
        {sent && (
          <div className="msg me img-bubble">
            <span className="bubble-img shot-art" />
          </div>
        )}
      </div>
      <div className="compose">
        <div className="compose-field" data-hit="chat-field">
          {pasted && !sent && <span className="paste-thumb shot-art" />}
          {!pasted && <span className="placeholder">Message</span>}
          {pasted && !sent && <span style={{ color: "var(--chat-sub)" }}>Screenshot.png</span>}
        </div>
        <div className={"send-btn" + (sendReady ? " ready" : "")} data-hit="send">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M12 19V6M6 12l6-6 6 6" />
          </svg>
        </div>
      </div>
    </div>
  );
}

/* ---------- masked value helpers ---------- */
function clipIsBinary(kind) {
  return kind === "image" || kind === "file" || kind === "audio" || kind === "other";
}
const HIDDEN_PLACEHOLDER = "\u2022\u2022\u2022\u2022\u2022\u2022";
function blurSplit(text, leading, trailing) {
  const chars = Array.from(text);
  const lead = Math.max(0, leading);
  const trail = Math.max(0, trailing);
  if (lead + trail >= chars.length) return { prefix: "", middle: text, suffix: "" };
  return {
    prefix: chars.slice(0, lead).join(""),
    middle: chars.slice(lead, chars.length - trail).join(""),
    suffix: chars.slice(chars.length - trail).join(""),
  };
}

function MaskedValue({ clip, revealLead, revealTrail }) {
  const masked = clip.maskMode && clip.maskMode !== "none" && !clip.revealed;
  if (masked && clip.maskMode === "blurred") {
    const seg = blurSplit(clip.preview, revealLead, revealTrail);
    return (
      <span className="pr-val">
        <span className="seg-prefix">{seg.prefix}</span>
        <span className="seg-mid">{seg.middle}</span>
        <span className="seg-suffix">{seg.suffix}</span>
      </span>
    );
  }
  if (masked && clip.maskMode === "hidden") {
    return <span className="pr-val"><span className="pr-hidden">{HIDDEN_PLACEHOLDER}</span></span>;
  }
  // shown, or revealed: blurred clips animate the blur away
  if (clip.maskMode === "blurred" && clip.revealed) {
    const seg = blurSplit(clip.preview, revealLead, revealTrail);
    return (
      <span className="pr-val revealed">
        <span className="seg-prefix">{seg.prefix}</span>
        <span className="seg-mid">{seg.middle}</span>
        <span className="seg-suffix">{seg.suffix}</span>
      </span>
    );
  }
  return <span className="pr-val">{clip.preview}</span>;
}

/* ---------- Cliplet popover ---------- */
function Popover({ open, left, top, clips, search, placeholder, selectedId, deleteConfirmId,
  flashId, footerHot, paused, sessionActive, revealLead, revealTrail, noFooter }) {
  return (
    <div className={"popover-wrap " + (open ? "open" : "closed")} style={{ left, top, width: 440 }}>
      <div className="notch" />
      <div className="popover">
        <div className="po-header" data-hit="search">
          {search ? (
            <span className="ph-query">{search}<span className="ph-caret" /></span>
          ) : (
            <span className="ph-placeholder">{placeholder || "Type to filter. Click to copy."}</span>
          )}
        </div>
        <div className="po-divider" />
        <div className="po-list">
          {clips.map((clip, i) => {
            const sel = clip.id === selectedId;
            const confirm = clip.id === deleteConfirmId;
            const aliasOut = clip.alias && clip.alias.trim() ? clip.alias.trim() : null;
            return (
              <div key={clip.id} data-hit={"row-" + clip.id}
                className={"po-row"
                  + (clipIsBinary(clip.kind) ? " binary" : "")
                  + (sel && !confirm ? " selected" : "")
                  + (confirm ? " confirm-delete" : "")
                  + (clip.id === flashId ? " flash" : "")}>
                {clip.ephemeral && <span className="pr-lead"><HourglassIcon size={11} /></span>}
                {clip.pinned && <span className="pr-lead"><PinIcon size={11} /></span>}
                <span className="pr-text">
                  <MaskedValue clip={clip} revealLead={revealLead} revealTrail={revealTrail} />
                  {aliasOut && <span className="pr-alias">{aliasOut}</span>}
                </span>
                {confirm
                  ? <span className="pr-del">Delete? ⌦ again</span>
                  : (i < 9 && <span className="pr-key">⌘{i + 1}</span>)}
              </div>
            );
          })}
        </div>
        <div className="po-divider" />
        {!noFooter && (
        <div className="po-footer">
          <div className={"po-foot-btn" + (footerHot === "pause" ? " hot" : "")} data-hit="foot-pause">{paused ? "Resume Cliplet" : "Pause Cliplet"}</div>
          <div className={"po-foot-btn" + (footerHot === "session" ? " hot" : "")} data-hit="foot-session">{sessionActive ? "End Temporary Session" : "Start Temporary Session"}</div>
          <div className="po-foot-sep" />
          <div className={"po-foot-btn" + (footerHot === "clear" ? " hot" : "")}>Clear</div>
          <div className="po-foot-sep" />
          <div className={"po-foot-btn" + (footerHot === "prefs" ? " hot" : "")}>Preferences</div>
          <div className={"po-foot-btn" + (footerHot === "quit" ? " hot" : "")}>Quit</div>
        </div>
        )}
      </div>
    </div>
  );
}

/* ---------- context / command menu (right-click) ---------- */
function CtxMenu({ left, top, items, hot }) {
  return (
    <div className="ctx-menu" style={{ left, top }}>
      {items.map((it, i) => it.sep
        ? <div key={i} className="ctx-sep" />
        : (
          <div key={i} className={"ctx-item" + (i === hot ? " hot" : "") + (it.destructive ? " destructive" : "")}>
            <span>{it.label}</span>
            {it.key && <span className="ci-key">{it.key}</span>}
          </div>
        ))}
    </div>
  );
}

/* ---------- Quick Look ---------- */
function QuickLook({ show, clip }) {
  return (
    <div className={"quicklook-scrim" + (show ? " show" : "")}>
      <div className="quicklook">
        <div className="ql-bar">
          <div className="ql-tl"><span style={{ background: "#ff5f57" }} /><span style={{ background: "#febc2e" }} /><span style={{ background: "#28c840" }} /></div>
          {clip ? clip.qlTitle : ""}
          <span className="ql-share">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
              <path d="M12 3v12M8 7l4-4 4 4M5 13v6a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-6" />
            </svg>
          </span>
        </div>
        <div className="ql-body">
          <div className="ql-image shot-art" />
          <div className="ql-meta">
            <span>{clip ? clip.qlDims : ""}</span>
            <span>{clip ? clip.qlSize : ""}</span>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ---------- Edit modal (alias + Show / Blur / Hide) ---------- */
function EditModal({ show, preview, alias, aliasFocus, mode, saveHot, cancelHot }) {
  const modes = [["none", "Show"], ["blurred", "Blur"], ["hidden", "Hide"]];
  return (
    <div className={"edit-scrim" + (show ? " show" : "")}>
      <div className="edit-modal">
        <div className="em-preview">{preview}</div>
        <div className="edit-group">
          <div className="edit-row">
            <span className="er-label">Alias</span>
            <span className={"er-field" + (aliasFocus ? " focus" : "")}>
              {alias ? <span>{alias}</span> : <span className="ef-placeholder">optional</span>}
              {aliasFocus && <span className="ef-caret" />}
            </span>
          </div>
          <div className="edit-row">
            <span className="er-label">Display</span>
            <span className="er-seg">
              {modes.map(([val, label]) => (
                <span key={val} className={"seg-opt" + (mode === val ? " on" : "")}>{label}</span>
              ))}
            </span>
          </div>
        </div>
        <div className="edit-actions">
          <span className={"edit-btn" + (cancelHot ? " hot" : "")}>Cancel</span>
          <span className={"edit-btn primary" + (saveHot ? " hot" : "")}>Save</span>
        </div>
      </div>
    </div>
  );
}

/* ---------- Confirm dialog (end temporary session) ---------- */
function ConfirmDialog({ show, count, dontAsk, keepHot, discardHot }) {
  return (
    <div className={"dialog-scrim" + (show ? " show" : "")}>
      <div className="dialog">
        <div className="dlg-icon"><HourglassIcon size={24} /></div>
        <div className="dlg-title">End temporary session?</div>
        <div className="dlg-msg">{count} clip{count === 1 ? "" : "s"} captured this session will be discarded. This can’t be undone.</div>
        <div className="dlg-check">
          <span className={"box" + (dontAsk ? " on" : "")}>
            {dontAsk && (
              <svg width="9" height="9" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round"><path d="M4 12l5 5L20 6" /></svg>
            )}
          </span>
          Don’t ask again
        </div>
        <div className="dlg-actions">
          <span className={"dlg-btn" + (keepHot ? " hot" : "")}>Keep All</span>
          <span className={"dlg-btn primary" + (discardHot ? " hot" : "")}>Discard</span>
        </div>
      </div>
    </div>
  );
}

/* ---------- "What others see" screen-share pane ---------- */
function SharePane({ show }) {
  return (
    <div className={"share-pane" + (show ? " show" : "")}>
      <div className="share-bar">
        <span className="sb-dot" style={{ background: "#ff5f57" }} />
        <span className="sb-dot" style={{ background: "#febc2e" }} />
        <span className="sb-dot" style={{ background: "#28c840" }} />
        <span style={{ marginLeft: 4 }}>What your audience sees</span>
        <span className="sb-rec"><span className="d" />REC</span>
      </div>
      <div className="share-body">
        <div className="share-mini">
          <div className="mini-wall" />
          <div className="mini-menubar" />
          <div className="mini-win" style={{ left: 22, top: 60, width: 150, height: 132 }}>
            <div className="mw-bar" />
          </div>
          <div className="mini-win" style={{ left: 196, top: 120, width: 120, height: 78 }}>
            <div className="mw-bar" />
          </div>
        </div>
        <div className="share-redact">
          <span className="sr-icon">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
              <path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z" opacity="0.4" />
              <path d="M4 4l16 16" />
              <path d="M9.5 9.7a3 3 0 0 0 4.2 4.2" />
            </svg>
          </span>
          <span className="sr-label">Cliplet hidden from this screen</span>
        </div>
      </div>
    </div>
  );
}

/* ---------- Pointer + key hint + caption ---------- */
function Pointer({ x, y, dur, clicking, down, hidden, right, z = 1 }) {
  return (
    <div className={"pointer" + (clicking ? " clicking" : "") + (down ? " down" : "")}
      style={{ left: x, top: y, "--cur-dur": dur + "ms", display: hidden ? "none" : "block" }}>
      <div style={{ transform: "scale(" + (1 / z) + ")", transformOrigin: "4px 2px" }}>
        <svg width="24" height="24" viewBox="0 0 24 24">
          <path d="M5 2l0 17 4.2-4.1 2.6 6.1 3.1-1.3-2.6-6 5.8 0z"
            fill="#fff" stroke="#1a1a1a" strokeWidth="1.2" strokeLinejoin="round" />
        </svg>
        <span className="click-ring" />
        {right && (
          <span style={{
            position: "absolute", left: 16, top: 14, fontSize: 9, fontWeight: 700,
            background: "rgba(20,20,24,0.9)", color: "#fff", padding: "1px 4px",
            borderRadius: 4, letterSpacing: "0.3px", whiteSpace: "nowrap",
          }}>right-click</span>
        )}
      </div>
    </div>
  );
}

function KeyHint({ show, label }) {
  return (
    <div className={"keyhint" + (show ? " show" : "")}>
      <span className="keycap">{label}</span>
    </div>
  );
}

function Caption({ show, scene, text }) {
  return (
    <div className={"caption" + (show ? " show" : "")}>
      {scene && <span className="scene-tag">{scene}</span>}{text}
    </div>
  );
}

Object.assign(window, {
  MenuBar, EditorWindow, ChatWindow, Popover, CtxMenu, QuickLook, EditModal, ConfirmDialog,
  SharePane, Pointer, KeyHint, Caption, clipIsBinary, blurSplit, MaskedValue,
});

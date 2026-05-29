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
function MbGlyphs() {
  // battery / wifi / spotlight / control-center — minimal monochrome
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
function MenuBar({ clipActive, clock }) {
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
        <MbGlyphs />
        <span data-hit="clip-icon" className={"mb-icon mb-clip" + (clipActive ? " active" : "")}>
          <Paperclip size={16} />
        </span>
        <span className="mb-clock">{clock}</span>
      </div>
    </div>
  );
}

/* ---------- Code editor window (ambient context) ---------- */
function EditorWindow() {
  const lines = [
    [["com", "// ClipletPopoverView.swift"]],
    [],
    [["key", "struct "], ["type", "ClipRowView"], ["", ": "], ["type", "View"], ["", " {"]],
    [["", "    "], ["key", "var"], ["", " body: "], ["key", "some "], ["type", "View"], ["", " {"]],
    [["", "        "], ["type", "HStack"], ["", "(spacing: "], ["num", "8"], ["", ") {"]],
    [["", "            "], ["type", "Text"], ["", "(prefix + clip."], ["fn", "preview"], ["", ")"]],
    [["", "                ."], ["fn", "lineLimit"], ["", "("], ["num", "1"], ["", ")"]],
    [["", "                ."], ["fn", "font"], ["", "(.system(size: "], ["num", "13"], ["", "))"]],
    [["", "            "], ["type", "Spacer"], ["", "(minLength: "], ["num", "12"], ["", ")"]],
    [["", "            "], ["key", "if"], ["", " index < "], ["num", "9"], ["", " {"]],
    [["", "                "], ["type", "Text"], ["", "("], ["str", "\"⌘\\(index + 1)\""], ["", ")"]],
    [["", "            }"]],
    [["", "        }"]],
    [["", "        ."], ["fn", "background"], ["", "(selected ? Color."], ["fn", "accentColor"], ["", " : ."], ["fn", "clear"], ["", ")"]],
    [["", "    }"]],
    [["", "}"]],
  ];
  return (
    <div className="win editor">
      <div className="win-titlebar">
        <div className="traffic"><span className="r" /><span className="y" /><span className="g" /></div>
        <span className="win-title">ClipletPopoverView.swift — Cliplet</span>
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

/* ---------- Cliplet popover ---------- */
function clipIsBinary(kind) {
  return kind === "image" || kind === "file" || kind === "audio" || kind === "other";
}

function Popover({ open, left, top, clips, search, selectedId, deleteConfirmId, flashId, footerHot }) {
  return (
    <div className={"popover-wrap " + (open ? "open" : "closed")} style={{ left, top, width: 440 }}>
      <div className="notch" />
      <div className="popover">
        <div className="po-header" data-hit="search">
          {search ? (
            <span className="ph-query">{search}<span className="ph-caret" /></span>
          ) : (
            <span className="ph-placeholder">Type to filter. Click to copy.</span>
          )}
        </div>
        <div className="po-divider" />
        <div className="po-list">
          {clips.map((clip, i) => {
            const sel = clip.id === selectedId;
            const confirm = clip.id === deleteConfirmId;
            return (
              <div key={clip.id} data-hit={"row-" + clip.id}
                className={"po-row"
                  + (clipIsBinary(clip.kind) ? " binary" : "")
                  + (sel && !confirm ? " selected" : "")
                  + (confirm ? " confirm-delete" : "")
                  + (clip.id === flashId ? " flash" : "")}>
                {clip.pinned && <span className="pr-pin">•</span>}
                <span className="pr-text">{clip.preview}</span>
                {confirm
                  ? <span className="pr-del">Delete? ⌦ again</span>
                  : (i < 9 && <span className="pr-key">⌘{i + 1}</span>)}
              </div>
            );
          })}
        </div>
        <div className="po-divider" />
        <div className="po-footer">
          <div className={"po-foot-btn" + (footerHot === "clear" ? " hot" : "")}>Clear</div>
          <div className={"po-foot-btn" + (footerHot === "prefs" ? " hot" : "")}>Preferences…</div>
          <div className={"po-foot-btn" + (footerHot === "quit" ? " hot" : "")}>Quit Cliplet</div>
        </div>
      </div>
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

/* ---------- Pointer + key hint + caption ---------- */
function Pointer({ x, y, dur, clicking, down, hidden }) {
  return (
    <div className={"pointer" + (clicking ? " clicking" : "") + (down ? " down" : "")}
      style={{ left: x, top: y, "--cur-dur": dur + "ms", display: hidden ? "none" : "block" }}>
      <svg width="24" height="24" viewBox="0 0 24 24">
        <path d="M5 2l0 17 4.2-4.1 2.6 6.1 3.1-1.3-2.6-6 5.8 0z"
          fill="#fff" stroke="#1a1a1a" strokeWidth="1.2" strokeLinejoin="round" />
      </svg>
      <span className="click-ring" />
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
  MenuBar, EditorWindow, ChatWindow, Popover, QuickLook, Pointer, KeyHint, Caption, clipIsBinary,
});

// MissAV Keep Playing
//
// manifest の "world": "MAIN" によりページ本体のコンテキストで document_start に実行される
// (CSP に阻まれる <script> 注入は不要)。missav の自動 pause は2系統ある:
//   (A) window/document の 'blur' と document の 'visibilitychange' で pause
//   (B) document.hidden / visibilityState を読んで pause
// (A) は本体より先に capture リスナーを張り stopImmediatePropagation で握りつぶす。
// (B) は Page Visibility API を常時 visible に固定して無効化する。
(() => {
  "use strict";

  // (B) Page Visibility API を常に「表示中」に見せる
  const spoof = (obj, prop, value) => {
    try {
      Object.defineProperty(obj, prop, { get: () => value, configurable: true });
    } catch (_) {}
  };
  spoof(Document.prototype, "hidden", false);
  spoof(Document.prototype, "webkitHidden", false);
  spoof(Document.prototype, "visibilityState", "visible");
  spoof(Document.prototype, "webkitVisibilityState", "visible");
  try {
    document.hasFocus = () => true;
  } catch (_) {}

  // (A) フォーカス喪失/タブ非表示イベントを本体リスナーより先に握りつぶす
  const block = (e) => {
    e.stopImmediatePropagation();
    e.stopPropagation();
  };
  const types = [
    "blur",
    "visibilitychange",
    "webkitvisibilitychange",
    "mozvisibilitychange",
    "pagehide",
  ];
  for (const t of types) {
    window.addEventListener(t, block, true);
    document.addEventListener(t, block, true);
  }
})();

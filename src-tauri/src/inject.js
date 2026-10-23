/*
 * Bingr voor Windows: draait bij het begin van elke pagina in het hoofdvenster (ook op https://bingr.online/web/).
 * - Onthoudt de MediaSession-acties van de speler (play, pause, nexttrack, …), zodat de mediatoetsen van het
 *   toetsenbord (globale sneltoetsen in main.rs) dezelfde actie doen als in de browser: window.__bingrMediaKey(k).
 * - F11: hele pagina volledig scherm (main.rs maakt dan ook het venster volledig scherm).
 * - Markeert de pagina met <html data-bingr-app="windows"> (alleen informatief; de webspeler hoeft er niets mee).
 * Geen netwerk, geen opslag, geen toegang tot Tauri.
 */
(function () {
  'use strict';
  if (window.__bingrMediaKey) return;
  var H = {};
  try {
    var ms = navigator.mediaSession;
    if (ms && typeof ms.setActionHandler === 'function') {
      var orig = ms.setActionHandler.bind(ms);
      ms.setActionHandler = function (action, fn) {
        H[action] = typeof fn === 'function' ? fn : null;
        return orig(action, fn);
      };
    }
  } catch (e) { /* geen MediaSession */ }

  function video() {
    var list = document.getElementsByTagName('video');
    for (var i = 0; i < list.length; i++) if (list[i].currentSrc || list[i].src) return list[i];
    return list[0] || null;
  }
  function call(action) {
    var fn = H[action];
    if (typeof fn !== 'function') return false;
    try { fn({ action: action }); return true; } catch (e) { return false; }
  }

  Object.defineProperty(window, '__bingrMediaKey', {
    configurable: false, enumerable: false, writable: false,
    value: function (k) {
      var v = video();
      if (k === 'playpause') {
        var paused = v ? v.paused : !(navigator.mediaSession && navigator.mediaSession.playbackState === 'playing');
        if (!call(paused ? 'play' : 'pause') && v) { if (paused) { var p = v.play(); if (p && p.catch) p.catch(function () {}); } else v.pause(); }
      } else if (k === 'stop') {
        if (!call('stop') && !call('pause') && v) v.pause();
      } else if (k === 'next') {
        if (!call('nexttrack')) call('seekforward');
      } else if (k === 'prev') {
        if (!call('previoustrack')) call('seekbackward');
      }
    }
  });

  document.addEventListener('keydown', function (e) {
    if (e.key !== 'F11' || e.defaultPrevented) return;
    e.preventDefault();
    try {
      if (document.fullscreenElement) document.exitFullscreen();
      else document.documentElement.requestFullscreen();
    } catch (x) { /* stil */ }
  }, true);

  try { document.documentElement.setAttribute('data-bingr-app', 'windows'); } catch (e) { /* stil */ }
})();

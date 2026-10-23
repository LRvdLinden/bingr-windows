/*
 * Bingr voor Windows: startpagina in de app (lokaal, ui/). Gaat door naar de webspeler op bingr.online zodra die
 * bereikbaar is; anders een offline-melding die het elke 10 seconden (en bij 'online') opnieuw probeert.
 * Ook het doel van main.rs als het laden van bingr.online later mislukt (?offline=1).
 */
(function () {
  'use strict';
  var PLAYER = 'https://bingr.online/web/';
  var PROBE = 'https://bingr.online/web/manifest.json';
  var en = !/^nl\b/i.test(navigator.language || '');
  if (en) {
    document.documentElement.lang = 'en';
    document.getElementById('t-title').textContent = 'No connection';
    document.getElementById('t-body').textContent = 'Bingr needs the internet to load your channels, movies and series. Check your connection; Bingr will try again by itself.';
    document.getElementById('retry').textContent = 'Try again';
  }
  var spin = document.getElementById('spin'), off = document.getElementById('off');
  var busy = false, timer = null;

  function offline() {
    spin.hidden = true; off.hidden = false;
    clearTimeout(timer); timer = setTimeout(tryOpen, 10000);
  }
  function tryOpen() {
    if (busy) return;
    busy = true; spin.hidden = false;
    var ctl = typeof AbortController === 'function' ? new AbortController() : null;
    var t = setTimeout(function () { if (ctl) ctl.abort(); }, 8000);
    // no-cors: alleen "is de server bereikbaar"; het antwoord zelf is niet nodig
    fetch(PROBE + '?t=' + Date.now(), { mode: 'no-cors', cache: 'no-store', signal: ctl ? ctl.signal : undefined })
      .then(function () { location.replace(PLAYER); })
      .catch(function () { busy = false; offline(); })
      .then(function () { clearTimeout(t); });
  }
  document.getElementById('retry').addEventListener('click', function () { busy = false; tryOpen(); });
  window.addEventListener('online', function () { busy = false; tryOpen(); });
  if (/[?&]offline=1/.test(location.search)) offline(); else tryOpen();
})();

// Bingr voor Windows: een lichte schil (Tauri v2, WebView2) rond de webspeler op https://bingr.online/web/
// (het adres staat in ui/app.js).
//
// - Start op de lokale pagina ui/index.html; die gaat door naar de webspeler zodra bingr.online bereikbaar is en toont
//   anders een offline-melding (met automatisch opnieuw proberen). Valt de verbinding later weg (laden mislukt), dan
//   komt dezelfde melding terug (WebView2 NavigationCompleted).
// - In het venster blijven alleen de webspeler en de accountpagina's van bingr.online; andere links (support, betalen,
//   Trakt, Plex, TMDb …) openen in de standaardbrowser.
// - Volledig scherm: het HTML5-volledig-scherm van de speler maakt ook het venster volledig scherm (WebView2
//   ContainsFullScreenElementChanged); F11 zet de hele pagina volledig scherm (inject.js).
// - Mediatoetsen (afspelen/pauze, stop, volgende, vorige) gaan naar de MediaSession-acties van de speler (inject.js).
// - Eén exemplaar tegelijk; venstergrootte en -positie worden onthouden.
// Geen IPC: de pagina's krijgen geen toegang tot Tauri-commando's (geen capabilities).
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use tauri::webview::{NewWindowResponse, PageLoadEvent};
use tauri::{AppHandle, Manager, Url, WebviewUrl, WebviewWindow, WebviewWindowBuilder};
use tauri_plugin_global_shortcut::{Code, GlobalShortcutExt, Shortcut, ShortcutState};
use tauri_plugin_opener::OpenerExt;

mod nav;
use nav::{external_ok, in_app, is_local};

const MAIN: &str = "main";
const INJECT: &str = include_str!("inject.js");

/// Externe links naar de standaardbrowser (alleen http/https/mailto).
fn open_external(app: &AppHandle, u: &Url) {
    if external_ok(u) {
        let _ = app.opener().open_url(u.as_str(), None::<&str>);
    }
}

fn offline_url() -> Url {
    #[cfg(windows)]
    let base = "http://tauri.localhost/index.html";
    #[cfg(not(windows))]
    let base = "tauri://localhost/index.html";
    Url::parse(&format!("{base}?offline=1")).expect("offline-url")
}

/// Optioneel logboek voor de rooktest in CI (BINGR_DEBUG_LOG=<bestand>): alleen geladen adressen, zonder query.
fn debug_log(line: &str) {
    if let Ok(p) = std::env::var("BINGR_DEBUG_LOG") {
        use std::io::Write;
        if let Ok(mut f) = std::fs::OpenOptions::new().create(true).append(true).open(p) {
            let _ = writeln!(f, "{line}");
        }
    }
}

fn media_key(app: &AppHandle, action: &str) {
    if let Some(w) = app.get_webview_window(MAIN) {
        let _ = w.eval(format!("window.__bingrMediaKey && window.__bingrMediaKey('{action}')"));
    }
}

fn show(app: &AppHandle) {
    if let Some(w) = app.get_webview_window(MAIN) {
        let _ = w.unminimize();
        let _ = w.show();
        let _ = w.set_focus();
    }
}

#[cfg(windows)]
fn hook_webview2(win: &WebviewWindow) {
    use webview2_com::{ContainsFullScreenElementChangedEventHandler, NavigationCompletedEventHandler};
    use webview2_com::Microsoft::Web::WebView2::Win32::{
        COREWEBVIEW2_WEB_ERROR_STATUS, COREWEBVIEW2_WEB_ERROR_STATUS_CANNOT_CONNECT,
        COREWEBVIEW2_WEB_ERROR_STATUS_CONNECTION_ABORTED, COREWEBVIEW2_WEB_ERROR_STATUS_CONNECTION_RESET,
        COREWEBVIEW2_WEB_ERROR_STATUS_DISCONNECTED, COREWEBVIEW2_WEB_ERROR_STATUS_HOST_NAME_NOT_RESOLVED,
        COREWEBVIEW2_WEB_ERROR_STATUS_SERVER_UNREACHABLE, COREWEBVIEW2_WEB_ERROR_STATUS_TIMEOUT,
    };
    use windows_core::BOOL;

    let w = win.clone();
    let _ = win.with_webview(move |pw| unsafe {
        let Ok(core) = pw.controller().CoreWebView2() else { return };

        // HTML5-volledig-scherm van de speler -> venster volledig scherm (en terug, ook met Esc)
        let wf = w.clone();
        let mut token = 0i64;
        let _ = core.add_ContainsFullScreenElementChanged(
            &ContainsFullScreenElementChangedEventHandler::create(Box::new(move |sender, _| {
                if let Some(s) = sender {
                    let mut fs = BOOL::default();
                    s.ContainsFullScreenElement(&mut fs)?;
                    let on = fs.as_bool();
                    let wf = wf.clone();
                    // niet binnen de WebView2-callback zelf: via de event loop
                    std::thread::spawn(move || {
                        let _ = wf.set_fullscreen(on);
                    });
                }
                Ok(())
            })),
            &mut token,
        );

        // laden van bingr.online mislukt (geen verbinding) -> offline-melding
        let wn = w.clone();
        let mut token2 = 0i64;
        let _ = core.add_NavigationCompleted(
            &NavigationCompletedEventHandler::create(Box::new(move |_sender, args| {
                if let Some(a) = args {
                    let mut ok = BOOL::default();
                    a.IsSuccess(&mut ok)?;
                    if !ok.as_bool() {
                        let mut st = COREWEBVIEW2_WEB_ERROR_STATUS::default();
                        a.WebErrorStatus(&mut st)?;
                        let offline = [
                            COREWEBVIEW2_WEB_ERROR_STATUS_CANNOT_CONNECT,
                            COREWEBVIEW2_WEB_ERROR_STATUS_CONNECTION_ABORTED,
                            COREWEBVIEW2_WEB_ERROR_STATUS_CONNECTION_RESET,
                            COREWEBVIEW2_WEB_ERROR_STATUS_DISCONNECTED,
                            COREWEBVIEW2_WEB_ERROR_STATUS_HOST_NAME_NOT_RESOLVED,
                            COREWEBVIEW2_WEB_ERROR_STATUS_SERVER_UNREACHABLE,
                            COREWEBVIEW2_WEB_ERROR_STATUS_TIMEOUT,
                        ]
                        .contains(&st);
                        debug_log(&format!("navigation-failed {}", st.0));
                        if offline {
                            let wn = wn.clone();
                            std::thread::spawn(move || {
                                let _ = wn.navigate(offline_url());
                            });
                        }
                    }
                }
                Ok(())
            })),
            &mut token2,
        );
    });
}

#[cfg(not(windows))]
fn hook_webview2(_win: &WebviewWindow) {}

fn main() {
    let shortcuts = [
        (Code::MediaPlayPause, "playpause"),
        (Code::MediaStop, "stop"),
        (Code::MediaTrackNext, "next"),
        (Code::MediaTrackPrevious, "prev"),
    ];

    tauri::Builder::default()
        // tweede start: het bestaande venster naar voren
        .plugin(tauri_plugin_single_instance::init(|app, _args, _cwd| show(app)))
        .plugin(tauri_plugin_window_state::Builder::default().build())
        .plugin(tauri_plugin_opener::init())
        .plugin(
            tauri_plugin_global_shortcut::Builder::new()
                .with_handler(move |app, sc, ev| {
                    if ev.state() != ShortcutState::Pressed {
                        return;
                    }
                    if let Some((_, a)) = shortcuts.iter().find(|(c, _)| *sc == Shortcut::new(None, *c)) {
                        media_key(app, a);
                    }
                })
                .build(),
        )
        .setup(move |app| {
            let handle = app.handle().clone();
            let nav_handle = handle.clone();
            let nw_handle = handle.clone();
            let win = WebviewWindowBuilder::new(app, MAIN, WebviewUrl::App("index.html".into()))
                .title("Bingr")
                .inner_size(1280.0, 800.0)
                .min_inner_size(480.0, 320.0)
                .background_color(tauri::window::Color(0, 0, 0, 255))
                .initialization_script(INJECT)
                .on_navigation(move |u| {
                    if in_app(u) {
                        return true;
                    }
                    open_external(&nav_handle, u);
                    false
                })
                .on_new_window(move |u, _features| {
                    // window.open / target=_blank: bingr.online-pagina's in hetzelfde venster, de rest in de browser
                    if in_app(&u) && !is_local(&u) {
                        if let Some(w) = nw_handle.get_webview_window(MAIN) {
                            let _ = w.navigate(u);
                        }
                    } else {
                        open_external(&nw_handle, &u);
                    }
                    NewWindowResponse::Deny
                })
                .on_page_load(|_w, p| {
                    if p.event() == PageLoadEvent::Finished {
                        let u = p.url();
                        debug_log(&format!("loaded {}://{}{}", u.scheme(), u.host_str().unwrap_or(""), u.path()));
                    }
                })
                .build()?;
            hook_webview2(&win);

            // mediatoetsen: alleen als ze vrij zijn (een andere app kan ze al hebben); fout = stil overslaan
            for (code, _) in shortcuts {
                match handle.global_shortcut().register(Shortcut::new(None, code)) {
                    Ok(()) => debug_log(&format!("shortcut {code:?} ok")),
                    Err(e) => debug_log(&format!("shortcut {code:?} niet vrij: {e}")),
                }
            }
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("Bingr kon niet starten");
}

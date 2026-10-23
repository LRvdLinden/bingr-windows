// Welke adressen blijven in het venster van Bingr (de rest opent in de standaardbrowser). Alleen de crate `url`, zodat
// dit los te testen is (tools/navtest, ook in de workflow Build).
use url::Url;

/// Paden van bingr.online die in de app blijven: de webspeler en de account- en inlogpagina's.
pub const IN_APP_PATHS: [&str; 5] = ["/web", "/account", "/koppelen", "/bevestigen", "/reset"];

/// Lokale pagina's van de app zelf (Windows: http://tauri.localhost, elders tauri://localhost).
pub fn is_local(u: &Url) -> bool {
    match u.scheme() {
        "tauri" => u.host_str() == Some("localhost"),
        "http" | "https" => u.host_str() == Some("tauri.localhost"),
        _ => false,
    }
}

pub fn in_app(u: &Url) -> bool {
    if is_local(u) || u.as_str() == "about:blank" {
        return true;
    }
    let host = u.host_str().unwrap_or("");
    u.scheme() == "https"
        && u.port().is_none()
        && (host == "bingr.online" || host == "www.bingr.online")
        && IN_APP_PATHS.iter().any(|p| u.path() == *p || u.path().starts_with(&format!("{p}/")))
}

/// Mag dit adres naar de standaardbrowser? (geen file:, javascript:, eigen protocollen e.d.)
pub fn external_ok(u: &Url) -> bool {
    matches!(u.scheme(), "http" | "https" | "mailto")
}

#[cfg(test)]
mod tests {
    use super::*;
    fn ok(s: &str) -> bool { in_app(&Url::parse(s).unwrap()) }

    #[test]
    fn in_de_app() {
        assert!(ok("https://bingr.online/web/"));
        assert!(ok("https://bingr.online/web/#/live"));
        assert!(ok("https://bingr.online/web"));
        assert!(ok("https://www.bingr.online/account/"));
        assert!(ok("https://bingr.online/koppelen/?mode=signup"));
        assert!(ok("https://bingr.online/reset/?x=1"));
        assert!(ok("http://tauri.localhost/index.html?offline=1"));
        assert!(ok("tauri://localhost/index.html"));
        assert!(ok("about:blank"));
    }

    #[test]
    fn naar_de_browser() {
        assert!(!ok("https://bingr.online/"));
        assert!(!ok("https://bingr.online/upgrade/"));
        assert!(!ok("https://bingr.online/website"));
        assert!(!ok("https://bingr.online/webx/"));
        assert!(!ok("http://bingr.online/web/"));
        assert!(!ok("https://bingr.online:8443/web/"));
        assert!(!ok("https://support.bingr.online/"));
        assert!(!ok("https://bingr.online.evil.example/web/"));
        assert!(!ok("https://evil.example/?u=https://bingr.online/web/"));
        assert!(!ok("https://trakt.tv/activate"));
        assert!(!ok("http://tauri.localhost.evil.example/"));
        assert!(!ok("file:///C:/Windows/"));
        assert!(!ok("data:text/html,hoi"));
    }

    #[test]
    fn externe_links() {
        let e = |s: &str| external_ok(&Url::parse(s).unwrap());
        assert!(e("https://support.bingr.online/") && e("http://example.com/") && e("mailto:support@bingr.online"));
        assert!(!e("file:///C:/Windows/system32/calc.exe") && !e("javascript:alert(1)") && !e("ms-settings:"));
    }
}

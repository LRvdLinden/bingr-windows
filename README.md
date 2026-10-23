# Bingr voor Windows

Installeerbare Windows-app (Windows 10 en 11, x64) van Bingr, de IPTV-speler voor je eigen servers. De app is een lichte
schil rond de webspeler op <https://bingr.online/web/>: zelfde account (Supabase, e-mail/wachtwoord of koppelcode),
servers (M3U, Xtream, MAC), Live TV, films en series, profielen, Mijn lijst en sync als in de browser.

- **Schil:** [Tauri v2](https://v2.tauri.app/) met de WebView2 van Windows (Chromium, al aanwezig op Windows 10/11; de
  installer zet hem anders zelf neer). Installer: NSIS `.exe` van een paar MB, per gebruiker (geen beheerdersrechten),
  Nederlands of Engels volgens de taal van Windows, met snelkoppeling in Start en verwijderen via *Apps*.
- **App-gegevens:** naam *Bingr*, uitgever *PixelForges*, identifier `nl.lrvdlinden.bingr.windows`, icoon uit de
  Bingr-brand (`bingr-beheer/presskit/brand/app-icons/AppIcon-1024.png`, met afgeronde hoeken; `src-tauri/icons/`).
- **Versie:** `version.properties` (`BINGR_VERSION=1.0.1`, `BINGR_BUILD=140`); bestandsversie van app en installer
  `1.0.1.140`. Zie [CLAUDE.md](CLAUDE.md) voor de buildnummer-reeks.

## Aanpak: live webspeler in plaats van een gebundelde kopie

Een kopie van `bingr-website/web/` in de app (vaste versie) werkt niet goed:

- de app-pagina's hebben op Windows de origin `http://tauri.localhost`. De backend-proxy `web-proxy` (M3U/Xtream-lijsten
  van http-servers en servers zonder CORS) staat POST-aanroepen alleen toe vanaf `https://bingr.online` en localhost,
  dus inloggen lukt, maar servers laden niet;
- de webspeler verwijst naar `../account/`, `../assets/` en andere pagina's van de site, en de pushmeldingen (service
  worker) en YouTube-trailers hangen aan de origin bingr.online.

Daarom laadt de app de **live** webspeler. Hij start op een kleine lokale pagina (`ui/`): die gaat door naar
`https://bingr.online/web/` zodra die bereikbaar is, en toont anders een offline-melding (NL/EN) die het elke 10 seconden
en bij *online* opnieuw probeert. Valt de verbinding later weg en mislukt het laden, dan komt dezelfde melding terug.
Voordeel: de Windows-app heeft altijd de nieuwste webspeler, zonder nieuwe installer. Afspelen gaat zoals in de browser
(hls.js / mpegts.js, http-streams via `web-proxy`); rechtstreeks afspelen zonder proxy via Tauri is bewust niet gedaan
(dan zou de webspeler een tweede netwerkpad nodig hebben).

Wat de schil zelf doet (`src-tauri/src/main.rs`, `inject.js`, `nav.rs`):

| Onderdeel | Hoe |
|---|---|
| Volledig scherm | Het HTML5-volledig-scherm van de speler maakt ook het **venster** volledig scherm (WebView2 `ContainsFullScreenElementChanged`); Esc gaat terug. F11 zet de pagina volledig scherm. |
| Mediatoetsen | Afspelen/pauze, stop, volgende en vorige (globale sneltoetsen) roepen de MediaSession-acties van de speler aan (volgende/vorige = zender zappen bij Live TV, volgende aflevering bij series). Heeft een andere app de toetsen al (bv. Spotify), dan slaat Bingr ze over. |
| Links | In het venster blijven alleen `bingr.online/web`, `/account`, `/koppelen`, `/bevestigen` en `/reset`. Andere links (upgrade/betalen, support, Trakt, Plex, TMDb, YouTube) openen in de standaardbrowser; `window.open` ook. |
| Eén exemplaar | Een tweede start brengt het bestaande venster naar voren. |
| Venster | Grootte en positie worden onthouden; zwarte achtergrond (geen witte flits). |
| Veiligheid | Geen IPC: de pagina's krijgen geen toegang tot Tauri-commando's (geen capabilities). Strikte CSP op de lokale pagina. Inloggegevens bewaart de webspeler zoals in de browser (WebView2-profiel in `%LOCALAPPDATA%\nl.lrvdlinden.bingr.windows`). |

## Bouwen

Workflow **Build** (`.github/workflows/build.yml`, `windows-latest`) bij elke push naar `main` (niet bij alleen `*.md`):

1. versie/build controleren (`tools/set_version.py --check`), syntaxis van de scripts, unit-tests van de navigatieregels
   (`tools/navtest`, `cargo test`);
2. ondertekenen klaarzetten als de secrets er zijn (zie hieronder);
3. `npx tauri build --bundles nsis` → `Bingr-<versie>-build<build>-setup.exe`;
4. controleren: grootte, bestandsversie `<versie>.<build>`, productnaam, en met secrets een geldige handtekening;
5. rooktest op de runner: stil installeren (`/S`), Bingr starten en kijken of de webspeler laadt (schermafbeelding),
   tweede start (één exemplaar), stil verwijderen;
6. **versleuteld aanleveren** bij de privé repo `LRvdLinden/bingr-inbox` (platform `windows`), daarna zet de workflow
   *Builds* van bingr-beheer hem in `builds/windows/` op de server en staat hij in het beheer onder **Downloads →
   Windows (.exe)**. Geen artefact, geen release: de installer staat nooit op GitHub.
7. logboeken en de schermafbeelding (inlogscherm, zonder account) op de branch `ci-logs`.

Lokaal (op Windows, met Rust en Node): `npm ci` en `npm run build` (installer in
`src-tauri/target/release/bundle/nsis/`), of `npm run dev`. Zonder Windows: `cargo test --manifest-path tools/navtest/Cargo.toml`.

### Secrets

| Secret | Nodig voor |
|---|---|
| `BINGR_INBOX_TOKEN` | Aanleveren bij bingr-inbox (fine-grained token, alleen `LRvdLinden/bingr-inbox`, *Contents: Read and write*; hetzelfde als in iptv-ios-appletv en bingr-android mag). Ontbreekt het, dan wordt niets aangeleverd (notice, workflow blijft groen). |
| `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `ARTIFACT_SIGNING_ENDPOINT`, `ARTIFACT_SIGNING_ACCOUNT`, `ARTIFACT_SIGNING_PROFILE` | Ondertekenen met Azure Artifact Signing (optie A). |
| `WINDOWS_CERT_PFX_BASE64`, `WINDOWS_CERT_PASSWORD` | Ondertekenen met een eigen certificaat als `.pfx` (optie B). |

## Ondertekenen (code signing)

Zonder handtekening toont Windows **SmartScreen** bij het openen van de installer *"Windows heeft uw pc beschermd"*
(onbekende uitgever; via *Meer informatie → Toch uitvoeren* gaat het wel). De workflow ondertekent automatisch zodra de
secrets er zijn: `bingr.exe`, de installer en het verwijderprogramma (Tauri `bundle.windows.signCommand` →
`tools/sign.ps1`, SHA-256 met tijdstempel). Zonder secrets bouwt hij onondertekend met een `::notice::`.

Belangrijk om te weten: **geen enkele handtekening haalt de SmartScreen-melding meteen weg.** Sinds 2024 krijgt ook een
EV-certificaat geen directe reputatie meer; reputatie bouwt op per uitgever naarmate meer mensen dezelfde ondertekende
app downloaden. Wel toont Windows na ondertekenen *PixelForges* (of de naam op het certificaat) als uitgever in plaats
van *Onbekende uitgever*, en volgende versies met dezelfde identiteit erven de opgebouwde reputatie.

| Optie | Kosten (globaal) | Voor wie | Opmerkingen |
|---|---|---|---|
| **A. Azure Artifact Signing** (voorheen *Trusted Signing*) | Basic ca. $9,99/maand (5.000 handtekeningen), Premium ca. $99,99/maand | Organisaties in de VS, Canada, EU en VK; **particulieren alleen in de VS en Canada** | Aanbevolen door Microsoft voor apps buiten de Store. Identiteitscontrole duurt een paar werkdagen; geen hardware-token nodig; certificaten van korte duur, beheerd door Microsoft; werkt direct in CI. Voor PixelForges in Nederland: alleen als organisatie (bedrijfsnaam zoals ingeschreven, bv. bij de KvK); controleer of de inschrijving als *organization* wordt geaccepteerd. |
| **B. OV-certificaat** (DigiCert, Sectigo, GlobalSign, SSL.com, Certum …) | ca. $150–300/jaar (wederverkopers soms goedkoper) | Wereldwijd, ook eenmanszaak/particulier (afhankelijk van de CA) | Sinds juni 2023 moet de privésleutel op een hardware-token of HSM staan: een gewone `.pfx` uit een bestand kan dan niet meer. In CI gebruik je dan de cloud-signing van de CA (bv. SSL.com eSigner, DigiCert KeyLocker, Certum SimplySign) of een HSM in Azure Key Vault; `tools/sign.ps1` is daarvoor eenvoudig uit te breiden. De `.pfx`-route hier (optie B in de workflow) is bedoeld voor certificaten die wél als bestand te exporteren zijn (bv. een intern of test-certificaat). |
| **C. EV-certificaat** | vanaf ca. $400/jaar | Bedrijven | Sinds 2024 geen voordeel meer bij SmartScreen ten opzichte van OV; alleen zinvol als een klant het eist. |
| **D. Microsoft Store** | Eenmalige registratie als ontwikkelaar | Iedereen | Store-installaties hebben geen SmartScreen-melding; de Store accepteert ook een `.exe`/`.msi`-installer (die moet dan wel zelf ondertekend zijn met een vertrouwd certificaat) of een MSIX-pakket dat Microsoft ondertekent. Valt buiten deze workflow. |
| Zelf ondertekend | gratis | alleen intern/testen | Windows vertrouwt het niet; voor publiek geen verbetering. |

**Optie A instellen (Artifact Signing):**

1. In Azure: resource *Artifact Signing account* aanmaken (regio bv. West Europe), *Identity validation* (Organization)
   doen, daarna een *Certificate profile* (*Public Trust*).
2. Een app-registratie (service principal) in Microsoft Entra ID met een client secret, en die de rol
   *Artifact Signing Certificate Profile Signer* geven op het account.
3. Secrets in deze repo: `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `ARTIFACT_SIGNING_ENDPOINT`
   (bv. `https://weu.codesigning.azure.net`, moet bij de regio van het account passen), `ARTIFACT_SIGNING_ACCOUNT`,
   `ARTIFACT_SIGNING_PROFILE`.
4. De workflow haalt de signtool-plug-in `Microsoft.ArtifactSigning.Client` (vaste versie) van NuGet, schrijft
   `metadata.json` buiten de repo en ondertekent met de tijdstempelserver van Microsoft. Controle: annotaties
   *Ondertekenen* en *Ondertekend* bij de run.

**Optie B instellen (.pfx):** `WINDOWS_CERT_PFX_BASE64` = de `.pfx` als base64 (PowerShell:
`[Convert]::ToBase64String([IO.File]::ReadAllBytes("cert.pfx"))`), `WINDOWS_CERT_PASSWORD` = het wachtwoord. De
workflow zet het certificaat alleen tijdelijk in het certificaatarchief van de runner en ondertekent met de
tijdstempel van DigiCert.

Bronnen (geraadpleegd 23 oktober 2026):

- Microsoft Learn, *Code signing options for Windows app developers*:
  <https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/code-signing-options>
- Microsoft Learn, *Set up signing integrations to use Artifact Signing* (SignTool, dlib, metadata.json, endpoints):
  <https://learn.microsoft.com/en-us/azure/artifact-signing/how-to-signing-integrations>
- Azure, *Artifact Signing pricing*: <https://azure.microsoft.com/en-us/pricing/details/trusted-signing/>
- DevClass, *Code signing Windows apps may be easier and more secure with new Azure Artifact service* (14 jan. 2026):
  <https://devclass.com/2026/01/14/code-signing-windows-apps-may-be-easier-and-more-secure-with-new-azure-artifact-service/>
- NuGet, *Microsoft.ArtifactSigning.Client*: <https://www.nuget.org/packages/microsoft.artifactsigning.client>

## Mappen

```
ui/                      lokale startpagina met offline-melding (index.html, app.js, style.css, logo.svg)
src-tauri/               Tauri-app (Rust): main.rs, nav.rs (welke links in de app blijven), inject.js, icons/, tauri.conf.json
tools/set_version.py     versie/build uit version.properties overal invullen (--check in CI)
tools/sign.ps1           ondertekenen (Artifact Signing of .pfx), aangeroepen door Tauri
tools/smoke.ps1          rooktest van de installer in CI
tools/navtest/           unit-tests van nav.rs zonder Tauri
CHANGELOG.md             uit docs/changelog.json van iptv-ios-appletv (make_changelog.py --windows)
```

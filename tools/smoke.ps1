# Rooktest van de installer op de Windows-runner (workflow Build): stil installeren (per gebruiker), Bingr starten met
# een debuglogboek (alleen geladen adressen en gebeurtenissen), eerst met bingr.online geblokkeerd (offline-melding),
# dan vrijgegeven (de app moet vanzelf de webspeler laden), F11 (volledig scherm) en de mediatoets afspelen/pauze,
# schermafbeeldingen (inlogscherm, zonder account), tweede start (één exemplaar), afsluiten en stil verwijderen.
# Harde fouten (exit 1): installeren, starten, crashen of verwijderen mislukt. Laadt bingr.online niet (netwerk van de
# runner), dan alleen een waarschuwing.
param(
  [Parameter(Mandatory = $true)][string]$Installer,
  [Parameter(Mandatory = $true)][string]$OutDir
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$log = Join-Path $OutDir 'app-debug.log'
Remove-Item $log -ErrorAction SilentlyContinue

function Fail($m) { Write-Host "::error title=Rooktest::$m"; exit 1 }

# 1. stil installeren (NSIS /S, installMode currentUser -> %LOCALAPPDATA%\Bingr)
$p = Start-Process -FilePath $Installer -ArgumentList '/S' -PassThru -Wait
if ($p.ExitCode -ne 0) { Fail "installer gaf exitcode $($p.ExitCode)" }
$dir = Join-Path $env:LOCALAPPDATA 'Bingr'
$exe = Get-ChildItem $dir -Filter *.exe -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '^uninstall' } | Select-Object -First 1
if (-not $exe) { Fail "geen Bingr.exe in $dir na installeren" }
$lnk = @(Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs" -Recurse -Filter 'Bingr*.lnk' -ErrorAction SilentlyContinue)
$v = $exe.VersionInfo
Write-Host "Geïnstalleerd: $($exe.Name) $($v.FileVersion) ($($v.ProductName)); snelkoppelingen in Start: $($lnk.Count)"
if ($lnk.Count -lt 1) { Write-Host "::warning title=Rooktest::geen snelkoppeling in het menu Start gevonden" }
$uninst = Join-Path $dir 'uninstall.exe'
if (-not (Test-Path $uninst)) { Fail 'uninstall.exe ontbreekt' }
$reg = Get-ChildItem 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue |
  ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object { $_.DisplayName -eq 'Bingr' } | Select-Object -First 1
if ($reg) { Write-Host "Apps en onderdelen: $($reg.DisplayName) $($reg.DisplayVersion), uitgever $($reg.Publisher)" }
else { Write-Host '::warning title=Rooktest::Bingr staat niet in Apps en onderdelen (HKCU Uninstall)' }

function Wait-Log($pattern, $seconds) {
  for ($i = 0; $i -lt $seconds; $i++) {
    if ($app.HasExited) { Fail "Bingr stopte (exitcode $($app.ExitCode))" }
    if ((Test-Path $log) -and (Select-String -Path $log -SimpleMatch $pattern -Quiet)) { return $true }
    Start-Sleep -Seconds 1
  }
  return $false
}
function Shot($name) {
  try {
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
    $bmp.Save((Join-Path $OutDir $name), [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
  } catch { Write-Host "Geen schermafbeelding: $($_.Exception.Message)" }
}

# 2. offline: bingr.online tijdelijk onbereikbaar (hosts-bestand van de runner) -> offline-melding, daarna weer online
$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsBak = Get-Content $hosts -Raw
$offlineTested = $false
try {
  Add-Content -Path $hosts -Value "`r`n0.0.0.0 bingr.online`r`n0.0.0.0 www.bingr.online" -ErrorAction Stop
  ipconfig /flushdns | Out-Null
  $offlineTested = $true
} catch { Write-Host "::warning title=Rooktest::hosts-bestand niet aan te passen; offline-test overgeslagen" }

$env:BINGR_DEBUG_LOG = $log
$app = Start-Process -FilePath $exe.FullName -PassThru
if ($offlineTested) {
  [void](Wait-Log 'loaded http://tauri.localhost/' 30)
  Start-Sleep -Seconds 12   # de startpagina probeert bingr.online (time-out 8 s) en toont dan de melding
  if (Select-String -Path $log -SimpleMatch 'loaded https://bingr.online/web/' -Quiet) { Fail 'webspeler geladen terwijl bingr.online geblokkeerd was' }
  Shot 'screenshot-offline.png'
  Set-Content -Path $hosts -Value $hostsBak -NoNewline
  ipconfig /flushdns | Out-Null
  Write-Host 'Offline: startpagina bleef staan; bingr.online weer vrijgegeven'
}

# 3. de webspeler moet laden (bij de offline-test vanzelf: de melding probeert het elke 10 s opnieuw)
$loaded = Wait-Log 'loaded https://bingr.online/web/' 90
Start-Sleep -Seconds 6   # webspeler laten opbouwen voor de schermafbeelding
if ($app.HasExited) { Fail "Bingr stopte (exitcode $($app.ExitCode))" }
if ($loaded) { Write-Host "::notice title=Rooktest::Bingr draait en de webspeler (https://bingr.online/web/) is geladen$(if ($offlineTested) { ' (na de offline-melding vanzelf opnieuw geprobeerd)' })" }
else { Write-Host '::warning title=Rooktest::Bingr draait, maar de webspeler van bingr.online is niet (op tijd) geladen' }
Shot 'screenshot.png'

# 4. volledig scherm met F11 (pagina -> venster) en een mediatoets (globale sneltoets -> MediaSession)
try {
  $ws = New-Object -ComObject WScript.Shell
  [void]$ws.AppActivate($app.Id)
  Start-Sleep -Seconds 1
  $ws.SendKeys('{F11}')
  if (Wait-Log 'fullscreen true' 10) {
    Start-Sleep -Seconds 2; Shot 'screenshot-fullscreen.png'
    $ws.SendKeys('{F11}')
    if (Wait-Log 'fullscreen false' 10) { Write-Host '::notice title=Rooktest::volledig scherm (F11) aan en uit werkt' }
    else { Write-Host '::warning title=Rooktest::volledig scherm ging niet uit met F11' }
  } else { Write-Host '::warning title=Rooktest::F11 gaf geen volledig scherm' }
  Add-Type -Namespace Bingr -Name Key -MemberDefinition '[DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, System.UIntPtr extra);'
  [Bingr.Key]::keybd_event(0xB3, 0, 0, [UIntPtr]::Zero); [Bingr.Key]::keybd_event(0xB3, 0, 2, [UIntPtr]::Zero)
  if (Wait-Log 'media playpause' 5) { Write-Host '::notice title=Rooktest::mediatoets afspelen/pauze komt bij de speler aan' }
  else { Write-Host '::warning title=Rooktest::mediatoets afspelen/pauze kwam niet aan' }
} catch { Write-Host "::warning title=Rooktest::volledig scherm/mediatoets niet te testen: $($_.Exception.Message)" }

# 5. verbinding valt weg terwijl de webspeler open is: herladen (F5) mislukt -> offline-melding, daarna vanzelf terug
if ($offlineTested -and $loaded) {
  try {
    # de webspeler houdt een verbinding open (HTTP/2): naast het hosts-bestand ook de adressen van bingr.online in de
    # firewall blokkeren (Windows controleert bestaande verbindingen opnieuw na een nieuwe regel)
    $ips = @(Resolve-DnsName bingr.online -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress } | ForEach-Object { $_.IPAddress })
    if ($ips) { New-NetFirewallRule -DisplayName 'Bingr rooktest offline' -Direction Outbound -Action Block -RemoteAddress $ips | Out-Null }
    Add-Content -Path $hosts -Value "`r`n0.0.0.0 bingr.online`r`n0.0.0.0 www.bingr.online"
    ipconfig /flushdns | Out-Null
    $before = @(Select-String -Path $log -SimpleMatch 'loaded https://bingr.online/web/').Count
    [void]$ws.AppActivate($app.Id); Start-Sleep -Seconds 1
    $ws.SendKeys('{F5}')
    $failed = Wait-Log 'navigation-failed' 20
    $back = $failed -and (Wait-Log 'loaded http://tauri.localhost/index.html' 10)
    if ($back) { Start-Sleep -Seconds 2; Shot 'screenshot-offline-later.png' }
    Remove-NetFirewallRule -DisplayName 'Bingr rooktest offline' -ErrorAction SilentlyContinue
    Set-Content -Path $hosts -Value $hostsBak -NoNewline
    ipconfig /flushdns | Out-Null
    if ($back) {
      $again = $false
      for ($i = 0; $i -lt 90 -and -not $again; $i++) { Start-Sleep -Seconds 1; $again = @(Select-String -Path $log -SimpleMatch 'loaded https://bingr.online/web/').Count -gt $before }
      if ($again) { Write-Host '::notice title=Rooktest::verbinding weg tijdens gebruik: offline-melding, daarna vanzelf terug naar de webspeler' }
      else { Write-Host '::warning title=Rooktest::na de offline-melding niet vanzelf terug naar de webspeler' }
    } else { Write-Host "::warning title=Rooktest::herladen zonder verbinding gaf geen offline-melding (navigation-failed: $failed)" }
  } catch { Write-Host "::warning title=Rooktest::offline tijdens gebruik niet te testen: $($_.Exception.Message)" }
  finally { Remove-NetFirewallRule -DisplayName 'Bingr rooktest offline' -ErrorAction SilentlyContinue; Set-Content -Path $hosts -Value $hostsBak -NoNewline }
}

# tweede start: mag geen tweede proces blijven (single instance), het bestaande venster komt naar voren
$second = Start-Process -FilePath $exe.FullName -PassThru
Start-Sleep -Seconds 4
if (-not $second.HasExited) { Write-Host '::warning title=Rooktest::tweede start bleef draaien (single instance?)'; Stop-Process -Id $second.Id -Force }
$procs = @(Get-Process -Name $exe.BaseName -ErrorAction SilentlyContinue)
Write-Host "Processen $($exe.BaseName): $($procs.Count)"

# 4. afsluiten en verwijderen
Get-Process -Name $exe.BaseName -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
Get-Content $log -ErrorAction SilentlyContinue | Select-Object -First 40 | ForEach-Object { Write-Host "  log: $_" }
$u = Start-Process -FilePath $uninst -ArgumentList '/S' -PassThru -Wait
# het NSIS-verwijderprogramma kopieert zichzelf en wacht niet altijd: even wachten tot Bingr.exe weg is
for ($i = 0; $i -lt 30 -and (Test-Path $exe.FullName); $i++) { Start-Sleep -Seconds 1 }
if (Test-Path $exe.FullName) { Fail 'Bingr.exe staat er nog na verwijderen' }
Write-Host '::notice title=Rooktest::stil installeren, starten, tweede start en verwijderen gelukt'
exit 0

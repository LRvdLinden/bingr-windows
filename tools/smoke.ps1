# Rooktest van de installer op de Windows-runner (workflow Build): stil installeren (per gebruiker), Bingr starten met
# een debuglogboek (alleen geladen adressen), kijken of het venster blijft draaien en de webspeler van bingr.online laadt,
# een schermafbeelding maken (inlogscherm, zonder account), afsluiten en stil verwijderen.
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

# 2. starten met debuglogboek
$env:BINGR_DEBUG_LOG = $log
$app = Start-Process -FilePath $exe.FullName -PassThru
$loaded = $false
for ($i = 0; $i -lt 60; $i++) {
  Start-Sleep -Seconds 1
  if ($app.HasExited) { Fail "Bingr stopte na $i s (exitcode $($app.ExitCode))" }
  if ((Test-Path $log) -and (Select-String -Path $log -SimpleMatch 'loaded https://bingr.online/web/' -Quiet)) { $loaded = $true; break }
}
Start-Sleep -Seconds 6   # webspeler laten opbouwen voor de schermafbeelding
if ($app.HasExited) { Fail "Bingr stopte (exitcode $($app.ExitCode))" }
if ($loaded) { Write-Host '::notice title=Rooktest::Bingr draait en de webspeler (https://bingr.online/web/) is geladen' }
else { Write-Host '::warning title=Rooktest::Bingr draait, maar de webspeler van bingr.online is niet (op tijd) geladen' }

# 3. schermafbeelding van het hoofdscherm
try {
  Add-Type -AssemblyName System.Windows.Forms, System.Drawing
  $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
  $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
  $bmp.Save((Join-Path $OutDir 'screenshot.png'), [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
} catch { Write-Host "Geen schermafbeelding: $($_.Exception.Message)" }

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

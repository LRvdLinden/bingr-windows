# Ondertekent één bestand (Authenticode, SHA-256, met tijdstempel). Tauri roept dit aan via bundle.windows.signCommand
# voor bingr.exe, de NSIS-installer en het verwijderprogramma; de workflow Build zet die instelling alleen als er
# ondertekensecrets zijn (zie README.md, "Ondertekenen").
#   BINGR_SIGN_MODE=azure : Azure Artifact Signing (voorheen Trusted Signing): signtool met de dlib uit NuGet
#                           Microsoft.ArtifactSigning.Client; BINGR_SIGN_DLIB, BINGR_SIGN_METADATA (metadata.json);
#                           inloggen via AZURE_TENANT_ID / AZURE_CLIENT_ID / AZURE_CLIENT_SECRET (EnvironmentCredential).
#   BINGR_SIGN_MODE=pfx   : certificaat (.pfx) dat de workflow in Cert:\CurrentUser\My heeft gezet; BINGR_SIGN_THUMBPRINT.
# Geen wachtwoorden of sleutels op de opdrachtregel of in het log.
param([Parameter(Mandatory = $true)][string]$File)
$ErrorActionPreference = 'Stop'

function Find-SignTool {
  if ($env:BINGR_SIGNTOOL -and (Test-Path $env:BINGR_SIGNTOOL)) { return $env:BINGR_SIGNTOOL }
  $c = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\signtool.exe" -ErrorAction SilentlyContinue |
    Sort-Object { [version]($_.Directory.Parent.Name -replace '[^0-9.]', '') } | Select-Object -Last 1
  if (-not $c) { throw 'signtool.exe niet gevonden (Windows SDK)' }
  return $c.FullName
}

if (-not (Test-Path -LiteralPath $File)) { throw "Bestand ontbreekt: $File" }
$st = Find-SignTool
# tijdstempel: Artifact Signing gebruikt die van Microsoft; een eigen certificaat standaard die van DigiCert (RFC 3161)
$ts = if ($env:BINGR_SIGN_TIMESTAMP) { $env:BINGR_SIGN_TIMESTAMP } elseif ($env:BINGR_SIGN_MODE -eq 'azure') { 'http://timestamp.acs.microsoft.com' } else { 'http://timestamp.digicert.com' }
$name = Split-Path -Leaf $File

switch ($env:BINGR_SIGN_MODE) {
  'azure' {
    if (-not (Test-Path $env:BINGR_SIGN_DLIB) -or -not (Test-Path $env:BINGR_SIGN_METADATA)) { throw 'Artifact Signing: dlib of metadata.json ontbreekt' }
    $sargs = @('sign', '/fd', 'SHA256', '/tr', $ts, '/td', 'SHA256', '/dlib', $env:BINGR_SIGN_DLIB, '/dmdf', $env:BINGR_SIGN_METADATA, $File)
  }
  'pfx' {
    if (-not $env:BINGR_SIGN_THUMBPRINT) { throw 'BINGR_SIGN_THUMBPRINT ontbreekt' }
    $sargs = @('sign', '/fd', 'SHA256', '/sha1', $env:BINGR_SIGN_THUMBPRINT, '/s', 'My', '/tr', $ts, '/td', 'SHA256', $File)
  }
  default { throw "Onbekende BINGR_SIGN_MODE '$($env:BINGR_SIGN_MODE)'" }
}

$ok = $false
for ($i = 1; $i -le 3 -and -not $ok; $i++) {
  & $st @sargs | Out-Host
  if ($LASTEXITCODE -eq 0) { $ok = $true } else { Write-Host "Ondertekenen van $name mislukt (poging $i)"; Start-Sleep -Seconds (5 * $i) }
}
if (-not $ok) { throw "Ondertekenen van $name mislukt" }
& $st verify /pa /q $File | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Handtekening van $name is niet geldig" }
Write-Host "Ondertekend: $name"

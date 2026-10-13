<#
.SYNOPSIS
  Builds Kao ID (served at /) and Secondhand (served at /secondhand/) into
  build/hosting for Firebase Hosting. See docs/DEPLOY_WEB.md.

.PARAMETER SiteUrl
  Public origin, e.g. https://<project-id>.web.app. Defaults to the web.app
  address of the default project in .firebaserc. http is only accepted for
  localhost rehearsals.

.PARAMETER EnvFile
  Public build values (deploy/web.env). Only SUPABASE_URL,
  SUPABASE_PUBLISHABLE_KEY and KAO_ID_CLIENT_ID are allowed.

.PARAMETER SecondhandDir
  Checkout of kaosure_secondhand.
#>
param(
  [string]$SiteUrl,
  [string]$EnvFile = (Join-Path $PSScriptRoot 'web.env'),
  [string]$SecondhandDir = (Join-Path $PSScriptRoot '..\..\kaosure_secondhand')
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$allowedKeys = @('SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'KAO_ID_CLIENT_ID')

function Fail([string]$message) {
  Write-Host "build_web: $message" -ForegroundColor Red
  exit 1
}

function Resolve-SiteUrl([string]$value) {
  if (-not $value) {
    $rc = Join-Path $root '.firebaserc'
    if (-not (Test-Path $rc)) { Fail 'pass -SiteUrl or set the default project in .firebaserc' }
    $project = (Get-Content $rc -Raw | ConvertFrom-Json).projects.default
    if (-not $project -or $project -like 'REPLACE-*') { Fail 'set the Firebase project ID in .firebaserc first' }
    $value = "https://$project.web.app"
  }
  $uri = $null
  if (-not [Uri]::TryCreate($value.TrimEnd('/'), [UriKind]::Absolute, [ref]$uri)) { Fail "not a URL: $value" }
  $local = $uri.Host -in @('localhost', '127.0.0.1')
  if ($uri.Scheme -ne 'https' -and -not ($local -and $uri.Scheme -eq 'http')) { Fail 'SiteUrl must be https' }
  if ($uri.AbsolutePath -ne '/' -or $uri.Query -or $uri.Fragment -or $uri.UserInfo) {
    Fail 'SiteUrl must be an origin only, e.g. https://<project-id>.web.app'
  }
  return $uri.GetLeftPart([UriPartial]::Authority)
}

function Test-SecretValue([string]$value) {
  if ($value -match '^sb_secret_' -or $value -match 'service_role') { return $true }
  $parts = $value.Split('.')
  if ($parts.Count -eq 3 -and $parts[0].StartsWith('eyJ')) {
    $payload = $parts[1].Replace('-', '+').Replace('_', '/')
    $payload += '=' * ((4 - $payload.Length % 4) % 4)
    try {
      $json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json
      if ($json.role -ne 'anon') { return $true }
    } catch { return $true }
  }
  return $false
}

function Assert-EnvFile([string]$path) {
  if (-not (Test-Path $path)) { Fail "missing $path (copy deploy/web.env.example)" }
  $seen = @{}
  foreach ($line in Get-Content $path) {
    $text = $line.Trim()
    if (-not $text -or $text.StartsWith('#')) { continue }
    $at = $text.IndexOf('=')
    if ($at -lt 1) { Fail "unreadable line in $path" }
    $key = $text.Substring(0, $at).Trim()
    $value = $text.Substring($at + 1).Trim().Trim('"', "'")
    if ($key -notin $allowedKeys) { Fail "$key is not allowed in $path; only $($allowedKeys -join ', ')" }
    if (Test-SecretValue $value) { Fail "$key looks like a secret key; use the publishable key" }
    $seen[$key] = $value
  }
  foreach ($key in $allowedKeys) {
    if (-not $seen[$key]) { Fail "$key is empty in $path" }
  }
  if (-not $seen['SUPABASE_URL'].StartsWith('https://')) { Fail 'SUPABASE_URL must be https' }
}

function Invoke-WebBuild([string]$dir, [string[]]$arguments) {
  Push-Location $dir
  try {
    & flutter build web --release @arguments
    if ($LASTEXITCODE -ne 0) { Fail "flutter build failed in $dir" }
  } finally {
    Pop-Location
  }
}

$site = Resolve-SiteUrl $SiteUrl
Assert-EnvFile $EnvFile
$EnvFile = (Resolve-Path $EnvFile).Path
if (-not (Test-Path (Join-Path $SecondhandDir 'pubspec.yaml'))) { Fail "Secondhand not found at $SecondhandDir" }
$SecondhandDir = (Resolve-Path $SecondhandDir).Path

Write-Host "Building for $site"
Invoke-WebBuild $root @(
  '--base-href', '/',
  "--dart-define-from-file=$EnvFile",
  "--dart-define=APP_URL=$site",
  '--dart-define=KAO_ID_ALLOWED_SERVICE_PATHS=/secondhand'
)
Invoke-WebBuild $SecondhandDir @(
  '--base-href', '/secondhand/',
  "--dart-define-from-file=$EnvFile",
  "--dart-define=KAO_ID_REDIRECT_URI=$site/secondhand/auth/callback",
  "--dart-define=KAO_ID_WEB_URL=$site"
)

$hosting = Join-Path $root 'build\hosting'
if (Test-Path $hosting) { Remove-Item $hosting -Recurse -Force }
Copy-Item (Join-Path $root 'build\web') $hosting -Recurse
Copy-Item (Join-Path $SecondhandDir 'build\web') (Join-Path $hosting 'secondhand') -Recurse

if (-not (Select-String -Path (Join-Path $hosting 'secondhand\index.html') -Pattern '<base href="/secondhand/">' -Quiet)) {
  Fail 'Secondhand index.html does not have <base href="/secondhand/">'
}

Write-Host ''
Write-Host "Ready in build\hosting for $site" -ForegroundColor Green
Write-Host "  Kao ID:     $site/"
Write-Host "  Secondhand: $site/secondhand/"
Write-Host "  Redirect:   $site/secondhand/auth/callback (must be registered on the OAuth client)"
Write-Host 'Deploy with: npx firebase-tools deploy --only hosting'

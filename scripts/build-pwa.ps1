# Build the React admin and Flutter PWA into admin/dist for Apache deploy.
# Admin stays at / ; PWA is served from /app/
#
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File scripts/build-pwa.ps1

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$adminDir = Join-Path $root "admin"
$mobileDir = Join-Path $root "mobile"
$distDir = Join-Path $adminDir "dist"
$appDir = Join-Path $distDir "app"
$apiBaseUrl = "https://upworkproposalapi.lyanethiopia.com"

Write-Host "Building admin SPA..."
Push-Location $adminDir
try {
    npm run build
} finally {
    Pop-Location
}

Write-Host "Building Flutter web PWA..."
Push-Location $mobileDir
try {
    flutter build web --release --pwa-strategy=offline-first --base-href /app/ --dart-define=API_BASE_URL=$apiBaseUrl
} finally {
    Pop-Location
}

$webBuild = Join-Path $mobileDir "build\web"
if (-not (Test-Path $webBuild)) {
    throw "Flutter web build not found at $webBuild"
}

Write-Host "Copying PWA into admin/dist/app..."
if (Test-Path $appDir) {
    Remove-Item $appDir -Recurse -Force
}
New-Item -ItemType Directory -Path $appDir | Out-Null
Copy-Item -Path (Join-Path $webBuild "*") -Destination $appDir -Recurse -Force

$htaccessSrc = Join-Path $mobileDir "web\.htaccess"
if (Test-Path $htaccessSrc) {
    Copy-Item $htaccessSrc (Join-Path $appDir ".htaccess") -Force
}

Write-Host "Done. Deploy the contents of admin/dist to the admin domain."
Write-Host "iPhone install URL: https://<admin-domain>/app/"

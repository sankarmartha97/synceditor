# Run Flutter in Production Mode

Write-Host "`n🚀 Starting Flutter in PRODUCTION mode..." -ForegroundColor Red
Write-Host "⚠️  WARNING: Running against production API!" -ForegroundColor Red
Write-Host "🔗 API: https://api.synceditor.com" -ForegroundColor Red
Write-Host "🌐 App: http://localhost:3000" -ForegroundColor Red
Write-Host ""

$confirmation = Read-Host "Are you sure you want to run against PRODUCTION? (yes/no)"
if ($confirmation -ne "yes") {
    Write-Host "❌ Cancelled" -ForegroundColor Yellow
    exit
}

flutter run -d chrome `
  --web-port=3000 `
  --dart-define=ENVIRONMENT=production `
  --dart-define=API_BASE_URL=https://api.synceditor.com `
  --dart-define=WS_URL=wss://api.synceditor.com `
  --dart-define=DEBUG=false `
  --web-browser-flag="--user-data-dir=C:\temp\chrome-profile-prod"

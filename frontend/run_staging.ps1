# Run Flutter in Staging Mode

Write-Host "`n🚀 Starting Flutter in STAGING mode..." -ForegroundColor Magenta
Write-Host "🔗 API: https://staging-api.synceditor.com" -ForegroundColor Magenta
Write-Host "🌐 App: http://localhost:3000" -ForegroundColor Magenta
Write-Host ""

flutter run -d chrome `
  --web-port=3000 `
  --dart-define=ENVIRONMENT=staging `
  --dart-define=API_BASE_URL=https://staging-api.synceditor.com `
  --dart-define=WS_URL=wss://staging-api.synceditor.com `
  --dart-define=DEBUG=true `
  --web-browser-flag="--user-data-dir=C:\temp\chrome-profile-staging"

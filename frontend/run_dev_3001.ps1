# Run Flutter in Development Mode (Localhost) - Instance 2
# Port 3001 with separate Chrome profile for multi-user testing

Write-Host "`n🚀 Starting Flutter in DEVELOPMENT mode (Instance 2)..." -ForegroundColor Green
Write-Host "🔗 API: http://localhost:5000" -ForegroundColor Green
Write-Host "🌐 App: http://localhost:3001" -ForegroundColor Green
Write-Host ""

flutter run -d chrome `
  --web-port=3001 `
  --dart-define=ENVIRONMENT=development `
  --dart-define=API_BASE_URL=http://localhost:5000 `
  --dart-define=WS_URL=ws://localhost:5000 `
  --dart-define=DEBUG=true `
  --web-browser-flag="--user-data-dir=C:\temp\chrome-profile-3001"

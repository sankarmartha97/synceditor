# Run Flutter with Local Network IP (for testing on other devices)
# Use your machine's local IP address

Write-Host "`n🚀 Starting Flutter with LOCAL NETWORK IP..." -ForegroundColor Yellow
Write-Host "🔗 API: http://192.168.1.153:5000" -ForegroundColor Yellow
Write-Host "🌐 App: http://localhost:3000" -ForegroundColor Yellow
Write-Host "📱 Access from other devices: http://192.168.1.153:3000" -ForegroundColor Yellow
Write-Host ""

flutter run -d chrome `
  --web-port=3000 `
  --dart-define=ENVIRONMENT=development `
  --dart-define=API_BASE_URL=http://192.168.1.153:5000 `
  --dart-define=WS_URL=ws://192.168.1.153:5000 `
  --dart-define=DEBUG=true `
  --web-browser-flag="--user-data-dir=C:\temp\chrome-profile-3000"

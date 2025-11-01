#!/usr/bin/env pwsh
# 🚀 RUN APP + VIEW LOGS

Write-Host "🚀 STARTING APP WITH LOGS..." -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if app is already running
$devices = flutter devices --machine | ConvertFrom-Json
if ($devices.Count -eq 0) {
    Write-Host "❌ No devices found!" -ForegroundColor Red
    Write-Host "   Please start emulator or connect phone" -ForegroundColor Yellow
    exit 1
}

Write-Host "📱 Available devices:" -ForegroundColor Yellow
$devices | ForEach-Object { Write-Host "   - $($_.name) ($($_.id))" -ForegroundColor White }
Write-Host ""

# Start app in background
Write-Host "🔧 Starting app in debug mode..." -ForegroundColor Cyan
Start-Process pwsh -ArgumentList "-Command", "cd '$PWD'; flutter run --debug" -WindowStyle Minimized

# Wait for app to start
Write-Host "⏳ Waiting for app to start (10 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Show logs
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "📊 LOGS (Filtered for Voice Control Debug)" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "💡 TIP: Press Ctrl+C to stop viewing logs" -ForegroundColor Yellow
Write-Host ""

# Filter and show logs
flutter logs | Select-String "DEBUG INFO|BẠN NÓI|SUCCESS|FAILED|EXCEPTION|CẢM BIẾN|THIẾT BỊ|HIỂN THỊ"

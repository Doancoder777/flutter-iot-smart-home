#!/usr/bin/env pwsh
# 🚀 BUILD & INSTALL SCRIPT

Write-Host "🚀 BUILDING APK..." -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Build APK
flutter build apk --release

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ BUILD SUCCESS!" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
    
    # APK location
    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    
    Write-Host ""
    Write-Host "📱 APK Location:" -ForegroundColor Yellow
    Write-Host "   $apkPath" -ForegroundColor White
    
    # File info
    if (Test-Path $apkPath) {
        $fileSize = (Get-Item $apkPath).Length / 1MB
        Write-Host ""
        Write-Host "📊 APK Size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "📲 NEXT STEPS:" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1️⃣  Connect phone via USB" -ForegroundColor White
    Write-Host "2️⃣  Enable USB Debugging" -ForegroundColor White
    Write-Host "3️⃣  Run: flutter install" -ForegroundColor White
    Write-Host ""
    Write-Host "OR" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📤 Copy APK to phone and install manually" -ForegroundColor White
    Write-Host ""
    
    # Ask to install
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    $install = Read-Host "Install to connected device now? (y/n)"
    
    if ($install -eq "y" -or $install -eq "Y") {
        Write-Host ""
        Write-Host "📲 Installing to device..." -ForegroundColor Cyan
        flutter install
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ INSTALLATION SUCCESS!" -ForegroundColor Green
            Write-Host ""
            Write-Host "🧪 NOW TEST VOICE CONTROL:" -ForegroundColor Yellow
            Write-Host "   1. Open app" -ForegroundColor White
            Write-Host "   2. Go to Voice Control" -ForegroundColor White
            Write-Host "   3. Try: 'Nhiệt độ bao nhiêu?'" -ForegroundColor White
            Write-Host ""
            Write-Host "📊 Check logs:" -ForegroundColor Yellow
            Write-Host "   flutter logs | Select-String 'DEBUG INFO'" -ForegroundColor White
            Write-Host ""
        } else {
            Write-Host ""
            Write-Host "❌ Installation failed" -ForegroundColor Red
            Write-Host "   Make sure:" -ForegroundColor Yellow
            Write-Host "   - Phone is connected via USB" -ForegroundColor White
            Write-Host "   - USB Debugging is enabled" -ForegroundColor White
            Write-Host "   - Phone is unlocked" -ForegroundColor White
            Write-Host ""
        }
    }
    
} else {
    Write-Host ""
    Write-Host "❌ BUILD FAILED!" -ForegroundColor Red
    Write-Host "Check errors above" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

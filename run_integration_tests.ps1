# Wandrr Integration Test - Quick Start Script
# Run this script to execute integration tests

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  Wandrr Integration Test Runner" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is available
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>&1 | Select-String "Flutter"
if ($flutterVersion) {
    Write-Host "✓ Flutter is installed" -ForegroundColor Green
    Write-Host $flutterVersion -ForegroundColor Gray
} else {
    Write-Host "✗ Flutter is not found in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter and add it to your PATH" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check for connected devices
Write-Host "Checking for available devices..." -ForegroundColor Yellow
$devices = flutter devices 2>&1
Write-Host $devices -ForegroundColor Gray
Write-Host ""

$deviceCount = ($devices | Select-String "•" | Measure-Object).Count
if ($deviceCount -eq 0) {
    Write-Host "✗ No devices found!" -ForegroundColor Red
    Write-Host "Please start an emulator or connect a device before running tests" -ForegroundColor Red
    Write-Host ""
    Write-Host "To start an Android emulator:" -ForegroundColor Yellow
    Write-Host "  1. Open Android Studio" -ForegroundColor White
    Write-Host "  2. Go to Tools > AVD Manager" -ForegroundColor White
    Write-Host "  3. Click the Play button on an emulator" -ForegroundColor White
    exit 1
}
Write-Host "✓ Found $deviceCount device(s)" -ForegroundColor Green
Write-Host ""

# Prompt for test credentials reminder
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  IMPORTANT: Test Credentials" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Before running tests, make sure you've updated the test credentials in:" -ForegroundColor Yellow
Write-Host "  integration_test/app_test.dart" -ForegroundColor White
Write-Host ""
Write-Host "Search for:" -ForegroundColor Yellow
Write-Host "  const testUsername = 'test@example.com';" -ForegroundColor White
Write-Host "  const testPassword = 'TestPassword123!';" -ForegroundColor White
Write-Host ""
$continue = Read-Host "Have you updated the test credentials? (y/n)"
if ($continue -ne 'y' -and $continue -ne 'Y') {
    Write-Host "Please update the credentials first, then run this script again." -ForegroundColor Yellow
    exit 0
}
Write-Host ""

# Run the tests
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  Running Integration Tests" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starting tests... This may take 30-60 seconds" -ForegroundColor Yellow
Write-Host ""

try {
    flutter test integration_test/app_test.dart

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "=================================================" -ForegroundColor Green
        Write-Host "  ✓ ALL TESTS PASSED!" -ForegroundColor Green
        Write-Host "=================================================" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "=================================================" -ForegroundColor Red
        Write-Host "  ✗ TESTS FAILED" -ForegroundColor Red
        Write-Host "=================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Common issues:" -ForegroundColor Yellow
        Write-Host "  1. Wrong credentials - Check Firebase Authentication" -ForegroundColor White
        Write-Host "  2. Network timeout - Increase pump durations" -ForegroundColor White
        Write-Host "  3. Widget not found - App UI may have changed" -ForegroundColor White
        Write-Host ""
        Write-Host "For more help, see INTEGRATION_TEST_GUIDE.md" -ForegroundColor Yellow
    }
} catch {
    Write-Host ""
    Write-Host "✗ Error running tests: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


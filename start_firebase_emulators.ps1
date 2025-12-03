# Start Firebase Emulators for Integration Tests
# This script starts Firebase Auth and Firestore emulators

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  Firebase Emulator Startup" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Firebase CLI is installed
Write-Host "Checking Firebase CLI installation..." -ForegroundColor Yellow
$firebaseVersion = firebase --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Firebase CLI is installed: $firebaseVersion" -ForegroundColor Green
} else {
    Write-Host "✗ Firebase CLI is not installed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install Firebase CLI using npm:" -ForegroundColor Yellow
    Write-Host "  npm install -g firebase-tools" -ForegroundColor White
    Write-Host ""
    exit 1
}
Write-Host ""

# Check firebase.json exists
if (-not (Test-Path "firebase.json")) {
    Write-Host "✗ firebase.json not found in current directory" -ForegroundColor Red
    Write-Host "Please run this script from the project root directory" -ForegroundColor Yellow
    exit 1
}

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  Starting Emulators" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starting Firebase emulators..." -ForegroundColor Yellow
Write-Host "  - Auth:      http://localhost:9099" -ForegroundColor White
Write-Host "  - Firestore: http://localhost:8080" -ForegroundColor White
Write-Host "  - UI:        http://localhost:4000" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the emulators" -ForegroundColor Yellow
Write-Host ""

# Start emulators
try {
    firebase emulators:start --only auth,firestore
} catch {
    Write-Host ""
    Write-Host "✗ Error starting emulators: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Check if ports 9099, 8080, or 4000 are already in use" -ForegroundColor White
    Write-Host "  2. Run 'firebase login' to authenticate" -ForegroundColor White
    Write-Host "  3. Run 'firebase init emulators' to configure emulators" -ForegroundColor White
    exit 1
}


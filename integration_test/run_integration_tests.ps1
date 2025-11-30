# Integration Test Runner Script for Windows PowerShell
# This script provides convenient commands to run integration tests

param(
    [string]$Command = "all",
    [string]$Device = "",
    [switch]$Verbose
)

# Colors for output
$SuccessColor = "Green"
$ErrorColor = "Red"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Show-Help {
    Write-ColorOutput "Integration Test Runner for Wandrr Travel Planner" $InfoColor
    Write-ColorOutput "=================================================" $InfoColor
    Write-Host ""
    Write-ColorOutput "Usage:" $WarningColor
    Write-Host "  .\run_integration_tests.ps1 [-Command <command>] [-Device <device_id>] [-Verbose]"
    Write-Host ""
    Write-ColorOutput "Commands:" $WarningColor
    Write-Host "  all              Run all integration tests (default)"
    Write-Host "  startup          Run startup page tests only"
    Write-Host "  login            Run login page tests only"
    Write-Host "  home             Run home page tests only"
    Write-Host "  trip-editor      Run trip editor page tests only"
    Write-Host "  list-devices     List available devices"
    Write-Host "  install-deps     Install test dependencies"
    Write-Host "  help             Show this help message"
    Write-Host ""
    Write-ColorOutput "Options:" $WarningColor
    Write-Host "  -Device <id>     Specify device ID to run tests on"
    Write-Host "  -Verbose         Show verbose output"
    Write-Host ""
    Write-ColorOutput "Examples:" $WarningColor
    Write-Host "  .\run_integration_tests.ps1"
    Write-Host "  .\run_integration_tests.ps1 -Command startup"
    Write-Host "  .\run_integration_tests.ps1 -Command all -Device chrome"
    Write-Host "  .\run_integration_tests.ps1 -Command login -Verbose"
    Write-Host ""
}

function Install-Dependencies {
    Write-ColorOutput "Installing test dependencies..." $InfoColor
    flutter pub get
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "Dependencies installed successfully!" $SuccessColor
    } else {
        Write-ColorOutput "Failed to install dependencies!" $ErrorColor
        exit 1
    }
}

function Get-Devices {
    Write-ColorOutput "Available devices:" $InfoColor
    flutter devices
}

function Run-Tests {
    param(
        [string]$TestName = "",
        [string]$DeviceId = "",
        [bool]$ShowVerbose = $false
    )

    $testFile = "integration_test\app_integration_test.dart"
    $command = "flutter test $testFile"

    if ($TestName -ne "") {
        $command += " --name `"$TestName`""
    }

    if ($DeviceId -ne "") {
        $command += " -d $DeviceId"
    }

    if ($ShowVerbose) {
        $command += " --verbose"
    }

    Write-ColorOutput "Running command: $command" $InfoColor
    Write-Host ""

    Invoke-Expression $command

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-ColorOutput "Tests completed successfully! ✓" $SuccessColor
    } else {
        Write-Host ""
        Write-ColorOutput "Tests failed! ✗" $ErrorColor
        exit 1
    }
}

# Main script logic
switch ($Command.ToLower()) {
    "help" {
        Show-Help
    }
    "list-devices" {
        Get-Devices
    }
    "install-deps" {
        Install-Dependencies
    }
    "all" {
        Write-ColorOutput "Running all integration tests..." $InfoColor
        Run-Tests -DeviceId $Device -ShowVerbose $Verbose
    }
    "startup" {
        Write-ColorOutput "Running startup page tests..." $InfoColor
        Run-Tests -TestName "Startup Page Tests" -DeviceId $Device -ShowVerbose $Verbose
    }
    "login" {
        Write-ColorOutput "Running login page tests..." $InfoColor
        Run-Tests -TestName "Login Page Tests" -DeviceId $Device -ShowVerbose $Verbose
    }
    "home" {
        Write-ColorOutput "Running home page tests..." $InfoColor
        Run-Tests -TestName "Home Page Tests" -DeviceId $Device -ShowVerbose $Verbose
    }
    "trip-editor" {
        Write-ColorOutput "Running trip editor page tests..." $InfoColor
        Run-Tests -TestName "Trip Editor Page Tests" -DeviceId $Device -ShowVerbose $Verbose
    }
    default {
        Write-ColorOutput "Unknown command: $Command" $ErrorColor
        Write-ColorOutput "Use '.\run_integration_tests.ps1 -Command help' for usage information." $WarningColor
        exit 1
    }
}


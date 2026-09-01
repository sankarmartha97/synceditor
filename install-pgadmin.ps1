# pgAdmin 4 Installation Script
# Run this in PowerShell as Administrator

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "pgAdmin 4 Installation Helper" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️  WARNING: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "   For Chocolatey install, please run PowerShell as Admin" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Choose installation method:" -ForegroundColor Green
Write-Host "1. Download pgAdmin installer (opens browser) - RECOMMENDED"
Write-Host "2. Install via Chocolatey (requires admin)"
Write-Host "3. Download DBeaver instead (alternative)"
Write-Host "4. Show connection info for manual install"
Write-Host ""

$choice = Read-Host "Enter your choice (1-4)"

switch ($choice) {
    "1" {
        Write-Host "Opening pgAdmin download page..." -ForegroundColor Green
        Start-Process "https://www.pgadmin.org/download/pgadmin-4-windows/"
        Write-Host ""
        Write-Host "✅ Browser opened!" -ForegroundColor Green
        Write-Host "1. Download the installer" -ForegroundColor White
        Write-Host "2. Run the .exe file" -ForegroundColor White
        Write-Host "3. Follow the installation wizard" -ForegroundColor White
        Write-Host "4. Launch pgAdmin after installation" -ForegroundColor White
    }
    
    "2" {
        if ($isAdmin) {
            Write-Host "Installing pgAdmin via Chocolatey..." -ForegroundColor Green
            choco install pgadmin4 -y
        } else {
            Write-Host "❌ ERROR: Chocolatey requires Administrator privileges" -ForegroundColor Red
            Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
        }
    }
    
    "3" {
        Write-Host "Opening DBeaver download page..." -ForegroundColor Green
        Start-Process "https://dbeaver.io/download/"
        Write-Host ""
        Write-Host "✅ Browser opened!" -ForegroundColor Green
        Write-Host "1. Download the Windows installer" -ForegroundColor White
        Write-Host "2. Run the .exe file" -ForegroundColor White
        Write-Host "3. Follow the installation wizard" -ForegroundColor White
    }
    
    "4" {
        Write-Host ""
        Write-Host "===== Canvas Editor Database Connection Info =====" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Host:     localhost" -ForegroundColor White
        Write-Host "Port:     5432" -ForegroundColor White
        Write-Host "Database: canvas_db" -ForegroundColor White
        Write-Host "Username: canvas_user" -ForegroundColor White
        Write-Host "Password: canvas_pass" -ForegroundColor White
        Write-Host ""
        Write-Host "Use these credentials in your GUI tool!" -ForegroundColor Green
    }
    
    default {
        Write-Host "Invalid choice. Please run the script again." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "After Installation:" -ForegroundColor Yellow
Write-Host "1. Launch pgAdmin or DBeaver" -ForegroundColor White
Write-Host "2. Create new PostgreSQL connection" -ForegroundColor White
Write-Host "3. Use connection info:" -ForegroundColor White
Write-Host "   Host: localhost, Port: 5432" -ForegroundColor Gray
Write-Host "   Database: canvas_db" -ForegroundColor Gray
Write-Host "   User: canvas_user, Pass: canvas_pass" -ForegroundColor Gray
Write-Host "4. Browse your Canvas Editor data!" -ForegroundColor White
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

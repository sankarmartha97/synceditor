# Canvas Editor - Database Installation Script
# Run this script as Administrator

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Canvas Editor - Database Setup" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. Right-click on PowerShell" -ForegroundColor Yellow
    Write-Host "2. Select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host "3. Navigate to this directory:" -ForegroundColor Yellow
    Write-Host "   cd c:\Users\RedoQ\KuickStudio_Work_Space\SyncEditor" -ForegroundColor Yellow
    Write-Host "4. Run: .\install_databases.ps1" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

Write-Host "✅ Running as Administrator" -ForegroundColor Green
Write-Host ""

# Step 1: Install PostgreSQL
Write-Host "📥 Step 1: Installing PostgreSQL 16..." -ForegroundColor Cyan
Write-Host ""

try {
    choco install postgresql16 --params '/Password:postgres' -y
    Write-Host "✅ PostgreSQL 16 installed successfully!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  PostgreSQL installation had issues. It may already be installed." -ForegroundColor Yellow
}

Write-Host ""

# Step 2: Install Redis
Write-Host "📥 Step 2: Installing Redis..." -ForegroundColor Cyan
Write-Host ""

try {
    choco install redis-64 -y
    Write-Host "✅ Redis installed successfully!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Redis installation had issues. It may already be installed." -ForegroundColor Yellow
}

Write-Host ""

# Step 3: Wait for services to start
Write-Host "⏳ Step 3: Waiting for services to start..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# Step 4: Configure PostgreSQL PATH
Write-Host ""
Write-Host "🔧 Step 4: Configuring environment..." -ForegroundColor Cyan

$pgPath = "C:\Program Files\PostgreSQL\16\bin"
$redisPath = "C:\Program Files\Redis"

# Add to PATH if not already there
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($currentPath -notlike "*$pgPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$pgPath", "Machine")
    Write-Host "✅ Added PostgreSQL to PATH" -ForegroundColor Green
}

if ($currentPath -notlike "*$redisPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$redisPath", "Machine")
    Write-Host "✅ Added Redis to PATH" -ForegroundColor Green
}

# Refresh PATH in current session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Step 5: Verify installations
Write-Host "🔍 Verifying installations..." -ForegroundColor Cyan
Write-Host ""

# Check PostgreSQL
try {
    $pgVersion = & "C:\Program Files\PostgreSQL\16\bin\psql.exe" --version 2>&1
    Write-Host "✅ PostgreSQL: $pgVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠️  PostgreSQL command not found (may need to restart terminal)" -ForegroundColor Yellow
}

# Check Redis
try {
    $redisStatus = Get-Service -Name Redis -ErrorAction SilentlyContinue
    if ($redisStatus) {
        if ($redisStatus.Status -eq 'Running') {
            Write-Host "✅ Redis: Service is running" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Redis: Service exists but not running. Starting..." -ForegroundColor Yellow
            Start-Service Redis
            Write-Host "✅ Redis: Service started" -ForegroundColor Green
        }
    } else {
        Write-Host "⚠️  Redis: Service not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not verify Redis status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Close and reopen PowerShell (to refresh PATH)" -ForegroundColor Yellow
Write-Host "2. Run the database setup script:" -ForegroundColor Yellow
Write-Host "   .\setup_database.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Or manually setup database:" -ForegroundColor Yellow
Write-Host '   psql -U postgres -c "CREATE DATABASE canvas_db;"' -ForegroundColor White
Write-Host '   psql -U postgres -c "CREATE USER canvas_user WITH PASSWORD ''canvas_pass'';"' -ForegroundColor White
Write-Host '   psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE canvas_db TO canvas_user;"' -ForegroundColor White
Write-Host ""

pause

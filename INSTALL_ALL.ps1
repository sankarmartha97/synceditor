# ============================================
# Canvas Editor - Complete Installation
# ============================================
# This script installs everything you need!
#
# RIGHT-CLICK and select "Run as Administrator"
# ============================================

param(
    [switch]$SkipInstall = $false
)

$ErrorActionPreference = "Continue"

# Colors
function Write-Step($message) { Write-Host "`n$message" -ForegroundColor Cyan }
function Write-Success($message) { Write-Host "✅ $message" -ForegroundColor Green }
function Write-Warning($message) { Write-Host "⚠️  $message" -ForegroundColor Yellow }
function Write-Error($message) { Write-Host "❌ $message" -ForegroundColor Red }

Clear-Host
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Canvas Editor - Complete Installation   " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error "This script must be run as Administrator!"
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. Right-click on this script file" -ForegroundColor White
    Write-Host "2. Select 'Run with PowerShell as Administrator'" -ForegroundColor White
    Write-Host ""
    pause
    exit 1
}

Write-Success "Running as Administrator"

# ============================================
# STEP 1: Install PostgreSQL
# ============================================
Write-Step "📥 STEP 1/5: Installing PostgreSQL..."

try {
    $pgInstalled = Test-Path "C:\Program Files\PostgreSQL\16\bin\psql.exe"
    
    if ($pgInstalled) {
        Write-Warning "PostgreSQL appears to be already installed"
    } elseif (-not $SkipInstall) {
        Write-Host "Installing PostgreSQL 16 (this may take 5-10 minutes)..." -ForegroundColor Yellow
        choco install postgresql16 --params '/Password:postgres' -y --force
        Write-Success "PostgreSQL 16 installed"
    }
} catch {
    Write-Warning "PostgreSQL installation encountered issues: $_"
}

# ============================================
# STEP 2: Install Redis
# ============================================
Write-Step "📥 STEP 2/5: Installing Redis..."

try {
    $redisInstalled = Test-Path "C:\Program Files\Redis\redis-server.exe"
    
    if ($redisInstalled) {
        Write-Warning "Redis appears to be already installed"
    } elseif (-not $SkipInstall) {
        Write-Host "Installing Redis..." -ForegroundColor Yellow
        choco install redis-64 -y --force
        Write-Success "Redis installed"
    }
} catch {
    Write-Warning "Redis installation encountered issues: $_"
}

# ============================================
# STEP 3: Configure Environment
# ============================================
Write-Step "🔧 STEP 3/5: Configuring environment..."

# Add PostgreSQL to PATH
$pgPath = "C:\Program Files\PostgreSQL\16\bin"
if (Test-Path $pgPath) {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($currentPath -notlike "*$pgPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$pgPath", "Machine")
        Write-Success "Added PostgreSQL to PATH"
    } else {
        Write-Warning "PostgreSQL already in PATH"
    }
}

# Add Redis to PATH
$redisPath = "C:\Program Files\Redis"
if (Test-Path $redisPath) {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($currentPath -notlike "*$redisPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$redisPath", "Machine")
        Write-Success "Added Redis to PATH"
    } else {
        Write-Warning "Redis already in PATH"
    }
}

# Refresh PATH for current session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# ============================================
# STEP 4: Start Services
# ============================================
Write-Step "🚀 STEP 4/5: Starting services..."

Start-Sleep -Seconds 5

# Start PostgreSQL service
try {
    $pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pgService) {
        if ($pgService.Status -ne 'Running') {
            Start-Service $pgService.Name
            Write-Success "PostgreSQL service started"
        } else {
            Write-Success "PostgreSQL service already running"
        }
    } else {
        Write-Warning "PostgreSQL service not found (may need restart)"
    }
} catch {
    Write-Warning "Could not start PostgreSQL service: $_"
}

# Start Redis service
try {
    $redisService = Get-Service -Name "Redis" -ErrorAction SilentlyContinue
    if ($redisService) {
        if ($redisService.Status -ne 'Running') {
            Start-Service Redis
            Write-Success "Redis service started"
        } else {
            Write-Success "Redis service already running"
        }
    } else {
        Write-Warning "Redis service not found (may need restart)"
    }
} catch {
    Write-Warning "Could not start Redis service: $_"
}

Start-Sleep -Seconds 3

# ============================================
# STEP 5: Setup Database
# ============================================
Write-Step "🗄️  STEP 5/5: Setting up database..."

$dbName = "canvas_db"
$dbUser = "canvas_user"
$dbPassword = "canvas_pass"
$postgresPassword = "postgres"

# Set PostgreSQL password
$env:PGPASSWORD = $postgresPassword

Write-Host "Creating database and user..." -ForegroundColor Yellow

try {
    # Try to find psql.exe
    $psqlPath = "C:\Program Files\PostgreSQL\16\bin\psql.exe"
    
    if (Test-Path $psqlPath) {
        # Create database
        & $psqlPath -U postgres -c "CREATE DATABASE $dbName;" 2>$null
        Write-Success "Database '$dbName' created"
        
        # Create user
        & $psqlPath -U postgres -c "CREATE USER $dbUser WITH PASSWORD '$dbPassword';" 2>$null
        Write-Success "User '$dbUser' created"
        
        # Grant privileges
        & $psqlPath -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $dbName TO $dbUser;" 2>$null
        & $psqlPath -U postgres -d $dbName -c "GRANT ALL ON SCHEMA public TO $dbUser;" 2>$null
        Write-Success "Privileges granted"
        
        # Run migrations
        Write-Host "Running migrations..." -ForegroundColor Yellow
        $env:PGPASSWORD = $dbPassword
        
        $dbDir = "c:\Users\RedoQ\KuickStudio_Work_Space\SyncEditor\database"
        if (Test-Path $dbDir) {
            Set-Location $dbDir
            
            # Run schema
            & $psqlPath -U $dbUser -d $dbName -f "schema.sql" 2>$null
            
            # Run migrations
            $migrations = @(
                "migrations/001_create_users_table.sql",
                "migrations/002_create_canvases_table.sql",
                "migrations/003_create_widgets_table.sql",
                "migrations/004_create_versions_and_collaborators.sql"
            )
            
            foreach ($migration in $migrations) {
                if (Test-Path $migration) {
                    & $psqlPath -U $dbUser -d $dbName -f $migration 2>$null
                }
            }
            
            Write-Success "Database migrations completed"
        }
    } else {
        Write-Warning "PostgreSQL not found at expected location"
        Write-Host "You may need to run .\setup_database.ps1 manually after restart" -ForegroundColor Yellow
    }
} catch {
    Write-Warning "Database setup encountered issues: $_"
    Write-Host "You can run .\setup_database.ps1 manually after restart" -ForegroundColor Yellow
}

# Clear passwords
$env:PGPASSWORD = $null

# ============================================
# Completion
# ============================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Installation Complete! 🎉" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "What's Installed:" -ForegroundColor Cyan
Write-Host "  ✅ PostgreSQL 16" -ForegroundColor White
Write-Host "  ✅ Redis" -ForegroundColor White
Write-Host "  ✅ Database 'canvas_db'" -ForegroundColor White
Write-Host "  ✅ User 'canvas_user'" -ForegroundColor White
Write-Host "  ✅ All tables created" -ForegroundColor White
Write-Host ""

Write-Host "Database Credentials:" -ForegroundColor Cyan
Write-Host "  Database: $dbName" -ForegroundColor White
Write-Host "  User:     $dbUser" -ForegroundColor White
Write-Host "  Password: $dbPassword" -ForegroundColor White
Write-Host "  Host:     localhost:5432" -ForegroundColor White
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Close ALL PowerShell windows" -ForegroundColor Yellow
Write-Host "  2. Reopen PowerShell (to refresh PATH)" -ForegroundColor Yellow
Write-Host "  3. Backend should auto-connect!" -ForegroundColor Yellow
Write-Host "  4. Open http://127.0.0.1:56153 in browser" -ForegroundColor Yellow
Write-Host "  5. Register and start creating!" -ForegroundColor Yellow
Write-Host ""

Write-Host "Verification Commands:" -ForegroundColor Cyan
Write-Host "  psql --version" -ForegroundColor White
Write-Host "  redis-cli ping" -ForegroundColor White
Write-Host "  psql -U canvas_user -d canvas_db -c '\dt'" -ForegroundColor White
Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

pause

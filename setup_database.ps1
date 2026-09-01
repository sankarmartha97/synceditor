# Canvas Editor - Database Setup Script
# Run this AFTER installing PostgreSQL and Redis

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Canvas Editor - Database Setup" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$postgresPassword = "postgres"
$dbName = "canvas_db"
$dbUser = "canvas_user"
$dbPassword = "canvas_pass"

# Set PGPASSWORD environment variable to avoid password prompt
$env:PGPASSWORD = $postgresPassword

Write-Host "🔧 Step 1: Creating database and user..." -ForegroundColor Cyan
Write-Host ""

# Create database
Write-Host "Creating database '$dbName'..." -ForegroundColor Yellow
try {
    & psql -U postgres -c "CREATE DATABASE $dbName;" 2>&1 | Out-Null
    Write-Host "✅ Database '$dbName' created" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Database may already exist" -ForegroundColor Yellow
}

# Create user
Write-Host "Creating user '$dbUser'..." -ForegroundColor Yellow
try {
    & psql -U postgres -c "CREATE USER $dbUser WITH PASSWORD '$dbPassword';" 2>&1 | Out-Null
    Write-Host "✅ User '$dbUser' created" -ForegroundColor Green
} catch {
    Write-Host "⚠️  User may already exist" -ForegroundColor Yellow
}

# Grant privileges
Write-Host "Granting privileges..." -ForegroundColor Yellow
try {
    & psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $dbName TO $dbUser;" 2>&1 | Out-Null
    & psql -U postgres -d $dbName -c "GRANT ALL ON SCHEMA public TO $dbUser;" 2>&1 | Out-Null
    Write-Host "✅ Privileges granted" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not grant privileges" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🗄️  Step 2: Running database migrations..." -ForegroundColor Cyan
Write-Host ""

# Change to database directory
$dbDir = "c:\Users\RedoQ\KuickStudio_Work_Space\SyncEditor\database"
Set-Location $dbDir

# Set password for canvas_user
$env:PGPASSWORD = $dbPassword

# Run schema
Write-Host "Running schema.sql..." -ForegroundColor Yellow
try {
    & psql -U $dbUser -d $dbName -f "schema.sql" 2>&1 | Out-Null
    Write-Host "✅ Schema created" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Schema creation had issues" -ForegroundColor Yellow
}

# Run migrations
$migrations = @(
    "001_create_users_table.sql",
    "002_create_canvases_table.sql",
    "003_create_widgets_table.sql",
    "004_create_versions_and_collaborators.sql"
)

foreach ($migration in $migrations) {
    $migrationPath = Join-Path "migrations" $migration
    if (Test-Path $migrationPath) {
        Write-Host "Running $migration..." -ForegroundColor Yellow
        try {
            & psql -U $dbUser -d $dbName -f $migrationPath 2>&1 | Out-Null
            Write-Host "✅ $migration completed" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  $migration had issues" -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️  $migration not found" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🔍 Step 3: Verifying database setup..." -ForegroundColor Cyan
Write-Host ""

# List tables
Write-Host "Tables in $dbName:" -ForegroundColor Yellow
try {
    & psql -U $dbUser -d $dbName -c "\dt"
    Write-Host ""
    Write-Host "✅ Database setup complete!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not list tables" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Database Credentials:" -ForegroundColor Cyan
Write-Host "  Database: $dbName" -ForegroundColor White
Write-Host "  User:     $dbUser" -ForegroundColor White
Write-Host "  Password: $dbPassword" -ForegroundColor White
Write-Host "  Host:     localhost" -ForegroundColor White
Write-Host "  Port:     5432" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Backend should automatically reconnect" -ForegroundColor Yellow
Write-Host "2. Check backend terminal for success messages" -ForegroundColor Yellow
Write-Host "3. Open http://127.0.0.1:56153 to test!" -ForegroundColor Yellow
Write-Host ""

# Clear password from environment
$env:PGPASSWORD = $null

pause

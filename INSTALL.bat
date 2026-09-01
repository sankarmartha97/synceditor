@echo off
:: Canvas Editor - Simple Installer
:: Right-click this file and select "Run as administrator"

echo =============================================
echo    Canvas Editor - Database Installation
echo =============================================
echo.

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script must be run as Administrator!
    echo.
    echo Please:
    echo 1. Right-click on this file
    echo 2. Select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo Running as Administrator... OK
echo.

:: Install PostgreSQL
echo ================================================
echo Installing PostgreSQL 16...
echo This may take 10-15 minutes. Please wait...
echo ================================================
echo.

choco install postgresql16 --params "/Password:postgres" -y --force

echo.
echo PostgreSQL installation complete!
echo.

:: Install Redis
echo ================================================
echo Installing Redis...
echo This may take 2-3 minutes. Please wait...
echo ================================================
echo.

choco install redis-64 -y --force

echo.
echo Redis installation complete!
echo.

:: Wait for services to start
echo Waiting for services to start...
timeout /t 10 /nobreak >nul

:: Start services
echo Starting services...
sc start postgresql-x64-16 >nul 2>&1
sc start Redis >nul 2>&1

timeout /t 5 /nobreak >nul

echo.
echo ================================================
echo Installation Complete!
echo ================================================
echo.
echo Next Steps:
echo 1. Close this window
echo 2. Close and reopen PowerShell
echo 3. Run: cd c:\Users\RedoQ\KuickStudio_Work_Space\SyncEditor
echo 4. Run: .\setup_database.ps1
echo.
echo Or manually setup database:
echo   psql -U postgres -c "CREATE DATABASE canvas_db;"
echo   psql -U postgres -c "CREATE USER canvas_user WITH PASSWORD 'canvas_pass';"
echo   psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE canvas_db TO canvas_user;"
echo.

pause

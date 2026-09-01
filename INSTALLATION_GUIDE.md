# Installation Guide - PostgreSQL & Redis for Windows

This guide will help you install PostgreSQL and Redis on Windows to run the Canvas Editor backend.

---

## 📥 Step 1: Install PostgreSQL

### Download PostgreSQL

1. **Go to the official download page**:
   - URL: https://www.postgresql.org/download/windows/
   - Or direct link: https://www.enterprisedb.com/downloads/postgres-postgresql-downloads

2. **Choose version**: PostgreSQL 16.x (latest stable)
   - Download the Windows x86-64 installer

3. **Run the installer** (PostgreSQL-16.x-windows-x64.exe)

### Installation Steps

1. **Click "Next"** through the welcome screen

2. **Installation Directory**: Keep default
   - Default: `C:\Program Files\PostgreSQL\16`

3. **Select Components**: Check all boxes
   - ✅ PostgreSQL Server
   - ✅ pgAdmin 4
   - ✅ Stack Builder
   - ✅ Command Line Tools

4. **Data Directory**: Keep default
   - Default: `C:\Program Files\PostgreSQL\16\data`

5. **Set Password**:
   - Enter a password for the `postgres` superuser
   - **Remember this password!** (e.g., `postgres`)
   - Confirm the password

6. **Port**: Keep default
   - Default: `5432`

7. **Locale**: Keep default
   - Default: `[Default locale]`

8. **Click "Next"** and then **"Install"**

9. **Wait for installation** (may take 5-10 minutes)

10. **Uncheck "Launch Stack Builder"** and click "Finish"

### Verify PostgreSQL Installation

Open PowerShell and run:
```powershell
# Check if PostgreSQL is installed
psql --version

# Should show: psql (PostgreSQL) 16.x
```

If the command is not found, add PostgreSQL to your PATH:
1. Search "Environment Variables" in Windows
2. Click "Environment Variables"
3. Under "System variables", find "Path"
4. Click "Edit"
5. Click "New"
6. Add: `C:\Program Files\PostgreSQL\16\bin`
7. Click "OK" on all dialogs
8. **Restart PowerShell**

---

## 📥 Step 2: Install Redis

### Option A: Using MSI Installer (Recommended)

1. **Download Redis for Windows**:
   - Go to: https://github.com/microsoftarchive/redis/releases
   - Download: `Redis-x64-3.0.504.msi` (latest release)

2. **Run the installer**:
   - Double-click the `.msi` file
   - Click "Next" through the wizard
   - **Check "Add the Redis installation folder to the PATH"**
   - Keep default port: `6379`
   - Click "Install"

3. **Verify Installation**:
   ```powershell
   # Check if Redis is running
   redis-cli ping
   # Should return: PONG
   ```

### Option B: Using Memurai (Redis Alternative for Windows)

If the above doesn't work, use Memurai (Redis-compatible):

1. **Download Memurai**:
   - Go to: https://www.memurai.com/get-memurai
   - Download the installer

2. **Install Memurai**:
   - Run the installer
   - Follow the installation wizard
   - Memurai will run as a Windows service

3. **Verify**:
   ```powershell
   memurai-cli ping
   # Should return: PONG
   ```

---

## 🛠️ Step 3: Configure PostgreSQL

### Create Database and User

1. **Open PowerShell as Administrator**

2. **Connect to PostgreSQL**:
   ```powershell
   psql -U postgres
   # Enter the password you set during installation
   ```

3. **Create Database and User**:
   ```sql
   -- Create database
   CREATE DATABASE canvas_db;
   
   -- Create user
   CREATE USER canvas_user WITH PASSWORD 'canvas_pass';
   
   -- Grant privileges
   GRANT ALL PRIVILEGES ON DATABASE canvas_db TO canvas_user;
   
   -- Connect to the database
   \c canvas_db
   
   -- Grant schema privileges
   GRANT ALL ON SCHEMA public TO canvas_user;
   
   -- Exit psql
   \q
   ```

### Run Database Migrations

```powershell
# Navigate to database folder
cd c:\Users\RedoQ\KuickStudio_Work_Space\SyncEditor\database

# Run migrations
psql -U canvas_user -d canvas_db -f schema.sql
psql -U canvas_user -d canvas_db -f migrations/001_create_users_table.sql
psql -U canvas_user -d canvas_db -f migrations/002_create_canvases_table.sql
psql -U canvas_user -d canvas_db -f migrations/003_create_widgets_table.sql
psql -U canvas_user -d canvas_db -f migrations/004_create_versions_and_collaborators.sql

# Optional: Load sample data
psql -U canvas_user -d canvas_db -f seeds/sample_data.sql
```

**Note**: You'll be prompted for the password (`canvas_pass`) for each migration.

---

## 🛠️ Step 4: Verify Installation

### Check PostgreSQL

```powershell
# Connect to database
psql -U canvas_user -d canvas_db

# List tables
\dt

# You should see:
# - users
# - canvases
# - widgets
# - canvas_versions
# - canvas_collaborators

# Exit
\q
```

### Check Redis

```powershell
# Test Redis
redis-cli ping
# Should return: PONG

# Set a test value
redis-cli SET test "Hello Redis"
# Should return: OK

# Get the value
redis-cli GET test
# Should return: "Hello Redis"
```

---

## 🚀 Step 5: Start Backend Server

Once PostgreSQL and Redis are installed and configured:

```powershell
# Navigate to backend folder
cd c:\Users\RedoQ\KuickStudio_Work_Space\SyncEditor\backend

# The backend is already trying to start
# It should automatically restart once databases are ready
```

If you need to manually restart:
```powershell
# Stop current backend (Ctrl+C in its terminal, or):
# Then start again:
npm run dev
```

---

## 🔍 Troubleshooting

### PostgreSQL Issues

**Problem**: "psql: command not found"
- **Solution**: Add PostgreSQL to PATH (see Step 1)

**Problem**: "FATAL: password authentication failed"
- **Solution**: Double-check username and password
- Reset password:
  ```powershell
  psql -U postgres
  ALTER USER canvas_user WITH PASSWORD 'canvas_pass';
  ```

**Problem**: "FATAL: database does not exist"
- **Solution**: Create the database (see Step 3)

**Problem**: "Connection refused"
- **Solution**: PostgreSQL service might not be running
  ```powershell
  # Check service status
  Get-Service -Name postgresql*
  
  # Start service
  Start-Service postgresql-x64-16
  ```

### Redis Issues

**Problem**: "Could not connect to Redis"
- **Solution**: Start Redis service
  ```powershell
  # Check if Redis is running
  Get-Service -Name Redis
  
  # Start Redis service
  Start-Service Redis
  ```

**Problem**: "redis-cli: command not found"
- **Solution**: Add Redis to PATH or use full path:
  ```powershell
  "C:\Program Files\Redis\redis-cli.exe" ping
  ```

### Backend Issues

**Problem**: Backend crashes with "ECONNREFUSED"
- **Solution**: Make sure PostgreSQL and Redis are running
  ```powershell
  # Check PostgreSQL
  psql -U postgres -c "SELECT version();"
  
  # Check Redis
  redis-cli ping
  ```

**Problem**: "Cannot find module 'pg'"
- **Solution**: Reinstall backend dependencies
  ```powershell
  cd backend
  rm -r node_modules
  npm install
  ```

---

## 📋 Quick Reference

### Default Ports
- **PostgreSQL**: 5432
- **Redis**: 6379
- **Backend API**: 5000
- **Frontend**: Auto-assigned by Flutter

### Default Credentials
- **PostgreSQL Admin**:
  - Username: `postgres`
  - Password: (what you set during installation)
  
- **Canvas App Database**:
  - Username: `canvas_user`
  - Password: `canvas_pass`
  - Database: `canvas_db`

### Service Commands

```powershell
# PostgreSQL
Get-Service postgresql*          # Check status
Start-Service postgresql-x64-16  # Start
Stop-Service postgresql-x64-16   # Stop
Restart-Service postgresql-x64-16 # Restart

# Redis
Get-Service Redis                # Check status
Start-Service Redis              # Start
Stop-Service Redis               # Stop
Restart-Service Redis            # Restart
```

---

## ✅ Installation Checklist

- [ ] PostgreSQL 16 installed
- [ ] PostgreSQL added to PATH
- [ ] PostgreSQL service running
- [ ] Database `canvas_db` created
- [ ] User `canvas_user` created
- [ ] Database migrations run
- [ ] Tables created (users, canvases, widgets, etc.)
- [ ] Redis installed
- [ ] Redis service running
- [ ] Redis responding to `ping` command
- [ ] Backend `.env` file configured
- [ ] Backend starts without errors

---

## 🎯 Next Steps

After completing the installation:

1. ✅ PostgreSQL and Redis running
2. ✅ Database created and migrated
3. ✅ Backend server starting successfully
4. ✅ Frontend connecting to backend
5. 🎉 Test full-stack application!

---

## 📞 Need Help?

If you encounter issues:
1. Check the troubleshooting section above
2. Review backend logs: Check the terminal where `npm run dev` is running
3. Check PostgreSQL logs: `C:\Program Files\PostgreSQL\16\data\log`
4. Check frontend console: Open browser developer tools (F12)

---

**Estimated Installation Time**: 20-30 minutes

**Last Updated**: 2026-08-26

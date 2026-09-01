# Installation Instructions - Final Step!

## 🚀 You're Almost There!

The backend code is ready and the frontend is already running. You just need to install PostgreSQL and Redis!

---

## ⚡ Quick Install (Using Scripts)

I've created automated scripts to make this easy!

### Step 1: Install PostgreSQL & Redis

**Right-click PowerShell → "Run as Administrator"**

Then run:
```powershell
cd c:\Users\RedoQ\KuickStudio_Work_Space\SyncEditor
.\install_databases.ps1
```

**This will:**
- ✅ Install PostgreSQL 16
- ✅ Install Redis
- ✅ Configure system PATH
- ✅ Start services

**Time**: 5-10 minutes (depending on download speed)

### Step 2: Setup Database

**In the same Administrator PowerShell:**
```powershell
.\setup_database.ps1
```

**This will:**
- ✅ Create `canvas_db` database
- ✅ Create `canvas_user` user
- ✅ Run all migrations
- ✅ Create tables (users, canvases, widgets, etc.)

**Time**: 1-2 minutes

### Step 3: Done! 🎉

The backend will automatically connect and you can start using the app!

---

## 🖱️ Manual Install (If Scripts Don't Work)

### Option 1: Using Chocolatey

**In PowerShell as Administrator:**
```powershell
# Install PostgreSQL
choco install postgresql16 --params '/Password:postgres' -y

# Install Redis
choco install redis-64 -y

# Start Redis service
Start-Service Redis
```

### Option 2: Using Installers

#### PostgreSQL:
1. Download: https://www.enterprisedb.com/downloads/postgres-postgresql-downloads
2. Run installer
3. Set password: `postgres`
4. Keep default port: `5432`

#### Redis:
1. Download: https://github.com/microsoftarchive/redis/releases
2. Download: `Redis-x64-3.0.504.msi`
3. Install with defaults

### Then Setup Database:

**In PowerShell:**
```powershell
# Create database
psql -U postgres -c "CREATE DATABASE canvas_db;"
psql -U postgres -c "CREATE USER canvas_user WITH PASSWORD 'canvas_pass';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE canvas_db TO canvas_user;"

# Run migrations
cd c:\Users\RedoQ\KuickStudio_Work_Space\SyncEditor\database
psql -U canvas_user -d canvas_db -f schema.sql
psql -U canvas_user -d canvas_db -f migrations/001_create_users_table.sql
psql -U canvas_user -d canvas_db -f migrations/002_create_canvases_table.sql
psql -U canvas_user -d canvas_db -f migrations/003_create_widgets_table.sql
psql -U canvas_user -d canvas_db -f migrations/004_create_versions_and_collaborators.sql
```

---

## ✅ Verification

### Check PostgreSQL:
```powershell
psql --version
# Should show: psql (PostgreSQL) 16.x

psql -U canvas_user -d canvas_db -c "\dt"
# Should list tables: users, canvases, widgets, etc.
```

### Check Redis:
```powershell
redis-cli ping
# Should return: PONG
```

### Check Backend:
Look at the backend terminal (where `npm run dev` is running). You should see:
```
✅ Database connected
✅ Redis connected
🚀 Server running on http://localhost:5000
```

### Check Frontend:
Open http://127.0.0.1:56153 - should show login screen

---

## 🎯 Test Everything

1. **Register**: Create a new account
2. **Add Widgets**: Drag from left panel to canvas
3. **Edit Properties**: Click widget → edit in right panel
4. **Real-time**: Open 2 tabs → changes sync instantly!
5. **Persistence**: Refresh page → widgets remain!

---

## 🔧 Troubleshooting

### Backend Still Shows Connection Error?

**Check PostgreSQL Service:**
```powershell
# Check status
Get-Service -Name postgresql*

# Start service
Start-Service postgresql-x64-16
```

**Check Redis Service:**
```powershell
# Check status
Get-Service -Name Redis

# Start service
Start-Service Redis
```

**Restart Backend:**
The backend should auto-restart, but if not:
- Go to backend terminal
- Press `rs` + Enter (to restart nodemon)
- Or Ctrl+C and run `npm run dev` again

### Can't Run Scripts?

**Enable script execution:**
```powershell
# In Administrator PowerShell:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### PostgreSQL Password Issues?

Default password is `postgres`. If you forgot it:
1. Uninstall PostgreSQL
2. Reinstall and set a new password
3. Update `.env` file in backend folder

---

## 📁 Important Files

- `install_databases.ps1` - Automated installer
- `setup_database.ps1` - Database setup
- `QUICK_START.md` - Quick reference guide
- `INSTALLATION_GUIDE.md` - Detailed manual
- `backend/.env` - Configuration (already set up)

---

## 🎉 What You'll Get

After installation, you'll have:
- ✅ User authentication (register/login)
- ✅ Canvas persistence (save/load)
- ✅ Real-time collaboration (multi-user sync)
- ✅ WebSocket updates (instant changes)
- ✅ REST API (18 endpoints)
- ✅ PostgreSQL database
- ✅ Redis caching

---

## 💡 Quick Commands Reference

```powershell
# Start PostgreSQL
Start-Service postgresql-x64-16

# Start Redis
Start-Service Redis

# Connect to database
psql -U canvas_user -d canvas_db

# Test Redis
redis-cli ping

# Restart backend
# Go to backend terminal and press: rs + Enter
```

---

**Estimated Total Time**: 15-20 minutes

**Ready?** Run `.\install_databases.ps1` as Administrator! 🚀

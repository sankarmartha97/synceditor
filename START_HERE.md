# 🚀 START HERE - Canvas Editor Installation

## Current Status

✅ **Frontend**: Running in Chrome at http://127.0.0.1:56153  
⏳ **Backend**: Waiting for PostgreSQL and Redis

---

## One-Click Installation

### Option 1: Automatic Install (Easiest!)

1. **Find this file**: `INSTALL_ALL.ps1`
2. **Right-click** on it
3. **Select**: "Run with PowerShell"
4. If prompted, click "Run anyway" or "Yes"
5. **Wait 10-15 minutes** for installation
6. **Done!** Close and reopen PowerShell

### Option 2: Step-by-Step

If automatic install doesn't work:

**Step 1**: Install databases
```powershell
# Right-click PowerShell → Run as Administrator
cd c:\Users\RedoQ\KuickStudio_Work_Space\SyncEditor
.\install_databases.ps1
```

**Step 2**: Setup database
```powershell
.\setup_database.ps1
```

**Step 3**: Restart PowerShell and check backend terminal!

---

## What to Expect

### During Installation:
- Installing PostgreSQL... (5-10 min)
- Installing Redis... (2-3 min)  
- Creating database... (1 min)
- Running migrations... (1 min)

### After Installation:
Look at your backend terminal (where `npm run dev` is running):
```
✅ Database connected
✅ Redis connected  
🚀 Server running on http://localhost:5000
🔌 WebSocket server ready
```

---

## Test the App

1. **Open**: http://127.0.0.1:56153
2. **Click**: "Register" button
3. **Create account**:
   - Name: Your Name
   - Email: your@email.com
   - Password: password123
4. **Start designing!**
   - Drag widgets from left panel
   - Click to select and edit
   - See real-time sync!

---

## Troubleshooting

### Script Won't Run?
**Enable scripts**:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Backend Still Not Connected?
**Check services**:
```powershell
# Check PostgreSQL
Get-Service postgresql*

# Check Redis  
Get-Service Redis

# Restart backend terminal (press Ctrl+C, then npm run dev)
```

### Need Manual Install?
See **README_INSTALL.md** for manual installation instructions.

---

## Files Reference

| File | Purpose |
|------|---------|
| **INSTALL_ALL.ps1** | ⭐ One-click installer (USE THIS!) |
| install_databases.ps1 | Install PostgreSQL & Redis only |
| setup_database.ps1 | Setup database only |
| README_INSTALL.md | Detailed manual instructions |
| QUICK_START.md | Quick reference guide |
| INSTALLATION_GUIDE.md | Complete installation manual |

---

## Need Help?

1. Check backend terminal for error messages
2. Check if services are running:
   ```powershell
   Get-Service postgresql*
   Get-Service Redis
   ```
3. Try restarting services:
   ```powershell
   Restart-Service postgresql-x64-16
   Restart-Service Redis
   ```

---

## Quick Commands

```powershell
# Verify PostgreSQL
psql --version
psql -U canvas_user -d canvas_db

# Verify Redis
redis-cli ping

# Check database tables
psql -U canvas_user -d canvas_db -c "\dt"

# Restart backend (in backend terminal)
rs + Enter
```

---

**Ready to install?**  
➡️ Right-click `INSTALL_ALL.ps1` and select "Run with PowerShell"

**Installation time**: 15-20 minutes  
**Your patience**: Worth it! 🎨

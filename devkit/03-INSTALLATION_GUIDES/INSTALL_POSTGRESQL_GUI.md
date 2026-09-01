# PostgreSQL GUI Installation Guide

Your Canvas Editor database is running and needs a GUI tool to view and manage data.

---

## 🎯 Recommended Options

### Option 1: **pgAdmin 4** (Official, Most Popular)
- Official PostgreSQL GUI
- Full-featured administration tool
- Free and open source

### Option 2: **DBeaver** (Universal Database Tool)
- Supports multiple databases
- Modern interface
- Free community edition

### Option 3: **Web-based Tools** (No Installation)
- Adminer (single PHP file)
- Use browser-based interface

---

## 🚀 OPTION 1: Install pgAdmin 4 (Recommended)

### Method A: Direct Download (Easiest)

1. **Download pgAdmin 4:**
   - Open browser and go to: https://www.pgadmin.org/download/pgadmin-4-windows/
   - Click "Download" for the latest Windows installer
   - Or direct link: https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v9.17/windows/pgadmin4-9.17-x64.exe

2. **Install:**
   - Run the downloaded .exe file
   - Click "Next" through the installer
   - Accept defaults (install location, start menu)
   - Click "Install"
   - Click "Finish"

3. **Launch pgAdmin:**
   - Start Menu → pgAdmin 4
   - Set master password (you'll use this to open pgAdmin)

4. **Connect to Canvas Editor Database:**
   - Click "Add New Server"
   - **General Tab:**
     - Name: `Canvas Editor DB`
   - **Connection Tab:**
     - Host: `localhost`
     - Port: `5432`
     - Database: `canvas_db`
     - Username: `canvas_user`
     - Password: `canvas_pass`
   - Click "Save"

### Method B: Using Chocolatey (Requires Admin PowerShell)

```powershell
# Open PowerShell as Administrator
# Right-click PowerShell → Run as Administrator

choco install pgadmin4 -y
```

---

## 🚀 OPTION 2: Install DBeaver (Alternative)

### Download and Install:

1. **Download DBeaver:**
   - Go to: https://dbeaver.io/download/
   - Click "Download" for Windows installer
   - Or direct: https://dbeaver.io/files/dbeaver-ce-latest-x86_64-setup.exe

2. **Install:**
   - Run the downloaded .exe file
   - Accept license
   - Choose install location
   - Click "Install"

3. **Launch DBeaver:**
   - Start Menu → DBeaver

4. **Connect to PostgreSQL:**
   - Click "New Database Connection" (plug icon)
   - Select "PostgreSQL"
   - Click "Next"
   - **Connection Settings:**
     - Host: `localhost`
     - Port: `5432`
     - Database: `canvas_db`
     - Username: `canvas_user`
     - Password: `canvas_pass`
     - Check "Save password"
   - Click "Test Connection" (it will download PostgreSQL driver)
   - Click "Finish"

---

## 🚀 OPTION 3: Browser-Based Adminer (Quick & Easy)

### Setup Adminer (No Installation Required):

1. **Download Adminer:**
   ```powershell
   cd C:\Users\RedoQ\KuickStudio_Work_Space\SyncEditor
   curl.exe -o adminer.php https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php
   ```

2. **Start PHP Server:**
   ```powershell
   # If you have PHP installed:
   php -S localhost:8080 adminer.php
   ```

3. **Or Use Node.js Server:**
   Create `adminer-server.js`:
   ```javascript
   const express = require('express');
   const { exec } = require('child_process');
   const app = express();
   
   app.get('/', (req, res) => {
       res.send('<h1>Use pgAdmin or DBeaver for better experience</h1>');
   });
   
   app.listen(8080, () => console.log('Server on http://localhost:8080'));
   ```

---

## 📊 What You Can Do with GUI Tools

### View Your Canvas Editor Data:

1. **Tables to Explore:**
   ```
   - users              (registered users)
   - canvases           (created canvases)
   - widgets            (canvas widgets)
   - canvas_collaborators (shared access)
   - widget_versions    (version history)
   ```

2. **Common Tasks:**
   - ✅ Browse all users and canvases
   - ✅ View widget details
   - ✅ Check relationships
   - ✅ Run SQL queries
   - ✅ Export data
   - ✅ Monitor database size
   - ✅ View query performance

3. **Sample Queries:**
   ```sql
   -- View all users
   SELECT * FROM users;
   
   -- View all canvases with owner info
   SELECT c.*, u.name as owner_name 
   FROM canvases c 
   JOIN users u ON c.owner_id = u.id;
   
   -- Count widgets per canvas
   SELECT c.name, COUNT(w.id) as widget_count
   FROM canvases c
   LEFT JOIN widgets w ON c.id = w.canvas_id
   GROUP BY c.id, c.name;
   
   -- View recent activity
   SELECT * FROM widget_versions 
   ORDER BY created_at DESC 
   LIMIT 10;
   ```

---

## 🎯 Quick Comparison

| Feature | pgAdmin | DBeaver | Adminer |
|---------|---------|---------|---------|
| Installation | Desktop app | Desktop app | Web file |
| Size | ~200MB | ~150MB | 500KB |
| PostgreSQL Focus | ✅ Dedicated | ❌ Multi-DB | ❌ Multi-DB |
| Features | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Learning Curve | Medium | Easy | Easy |
| Visual Query Builder | ✅ | ✅ | ❌ |
| ER Diagrams | ✅ | ✅ | ❌ |
| Best For | PostgreSQL Admin | Multi-DB Dev | Quick Access |

---

## 🔧 Current Database Info

**Your Canvas Editor Database:**
```
Host:     localhost
Port:     5432
Database: canvas_db
Username: canvas_user
Password: canvas_pass
```

**Database Schema:**
- ✅ 5 tables created
- ✅ All migrations applied
- ✅ Test data from API tests available

---

## 📝 Recommended Choice

### For You: **pgAdmin 4**
**Why?**
- Official PostgreSQL tool
- Best for PostgreSQL-specific features
- Comprehensive admin capabilities
- Active development and support

**Installation Steps:**
1. Download from: https://www.pgadmin.org/download/
2. Run installer
3. Launch pgAdmin
4. Add server with credentials above
5. Done! Browse your Canvas Editor data

---

## 🆘 Need Help?

### Can't Install?
- Try DBeaver instead (easier installer)
- Check if you have admin rights
- Temporarily disable antivirus

### Connection Issues?
- Verify PostgreSQL is running:
  ```powershell
  Get-Service -Name postgresql*
  ```
- Test connection:
  ```powershell
  psql -U canvas_user -d canvas_db
  ```

### Want to See Data Now?
Use command line:
```powershell
# Connect to database
psql -U canvas_user -d canvas_db

# List tables
\dt

# View users
SELECT * FROM users;

# View canvases
SELECT * FROM canvases;

# Exit
\q
```

---

## ✅ Next Steps

1. **Install pgAdmin or DBeaver** (takes 2-3 minutes)
2. **Connect to canvas_db**
3. **Browse your Canvas Editor data**
4. **Run SQL queries to explore**

**Ready to install? Which option do you prefer?**
- Option 1: pgAdmin 4 (official)
- Option 2: DBeaver (modern)
- Option 3: Command line is fine


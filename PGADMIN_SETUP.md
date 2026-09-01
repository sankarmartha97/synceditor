# 🎯 pgAdmin Setup - Complete Guide

## ✅ Current Status

**Your browser should now be open to the pgAdmin download page.**

If not, open: **https://www.pgadmin.org/download/pgadmin-4-windows/**

---

## 📥 STEP 1: Download pgAdmin (1 minute)

1. On the download page, click the **"Download"** button
2. The file will download to your Downloads folder
3. File name will be something like: `pgadmin4-x.xx-x64.exe`

---

## 💿 STEP 2: Install pgAdmin (2 minutes)

1. **Open the downloaded file** from your Downloads folder
2. Click **"Yes"** if Windows asks for permission
3. Installation wizard will open:
   - Click **"Next"**
   - Accept the License Agreement → **"Next"**
   - Leave default installation folder → **"Next"**
   - Click **"Install"**
   - Wait for installation (1-2 minutes)
   - Click **"Finish"**

---

## 🚀 STEP 3: Launch pgAdmin (30 seconds)

1. Press **Windows key**
2. Type: **"pgAdmin 4"**
3. Click to open
4. **First launch**: Set a master password (you'll use this to open pgAdmin)
   - Choose any password you like (e.g., "admin123")
   - Re-enter to confirm
   - Click **"OK"**

---

## 🔌 STEP 4: Connect to Canvas Editor Database (1 minute)

### Add New Server:

1. In pgAdmin, right-click on **"Servers"** (left sidebar)
2. Select **"Register"** → **"Server..."**

### General Tab:
```
Name: Canvas Editor DB
```
(This is just a friendly name, you can use anything)

### Connection Tab:
```
Host name/address:    localhost
Port:                 5432
Maintenance database: canvas_db
Username:             canvas_user
Password:             canvas_pass
```

3. **Check** the box: ✅ **"Save password"** (so you don't have to enter it each time)
4. Click **"Save"**

---

## 🎨 STEP 5: Browse Your Data!

### View Tables:

1. In the left sidebar, expand:
   ```
   Servers
   └── Canvas Editor DB
       └── Databases
           └── canvas_db
               └── Schemas
                   └── public
                       └── Tables
   ```

2. You'll see **5 tables**:
   - **users** - All registered users
   - **canvases** - All created canvases
   - **widgets** - All widgets on canvases
   - **canvas_collaborators** - Shared canvas access
   - **widget_versions** - Version history

### View Data in a Table:

1. **Right-click** on any table (e.g., "users")
2. Select **"View/Edit Data"** → **"All Rows"**
3. Data appears in the right panel!

---

## 📊 What You'll See

### Current Database Content:

From our API tests:
```
✅ 1 user registered
   - Email: test_1787767496114@example.com
   - Name: Test User

✅ 0 canvases (deleted after testing)
✅ 0 widgets (deleted after testing)
✅ Database size: 8.38 MB
```

**This is normal!** The test script cleaned up after itself. When you use the app:
- Register a real user
- Create canvases
- Add widgets
- You'll see all this data in pgAdmin!

---

## 🎯 Common Tasks in pgAdmin

### 1. View All Users:
```sql
SELECT * FROM users;
```

### 2. View Canvases with Owner Names:
```sql
SELECT c.*, u.name as owner_name 
FROM canvases c 
JOIN users u ON c.owner_id = u.id;
```

### 3. Count Widgets Per Canvas:
```sql
SELECT c.name, COUNT(w.id) as widget_count
FROM canvases c
LEFT JOIN widgets w ON c.id = w.canvas_id
GROUP BY c.id, c.name;
```

### To Run Queries:

1. Click **"Tools"** → **"Query Tool"**
2. Paste SQL query
3. Click **"Execute/Run"** (▶️ button) or press **F5**
4. Results appear below!

---

## 🔍 pgAdmin Interface Overview

### Left Sidebar (Browser):
- Navigate database structure
- Expand/collapse tables, schemas, etc.

### Right Panel (Dashboard/Data):
- View table data
- Run queries
- See statistics

### Top Menu:
- **File**: Import/Export
- **Tools**: Query Tool, Backup, Restore
- **Help**: Documentation

---

## 💡 Pro Tips

### Quick Navigation:
- **Double-click** folders to expand/collapse
- **Right-click** anything for context menu
- **F5** in Query Tool to run query

### Viewing Data:
- **View/Edit Data → All Rows**: See everything
- **View/Edit Data → First 100 Rows**: Quick preview
- **View/Edit Data → Filtered Rows**: Custom filter

### Refreshing:
- **Right-click table** → **Refresh** to see new data
- Or press **F5** while table is selected

---

## 🐛 Troubleshooting

### Can't Connect?

**Check PostgreSQL is running:**
```powershell
Get-Service -Name postgresql*
```

**Start if stopped:**
```powershell
Start-Service postgresql*
```

### Wrong Password?

Double-check credentials:
```
Username: canvas_user
Password: canvas_pass
```

### Can't Find pgAdmin?

Search in Start Menu: "pgAdmin 4"

---

## ✅ Verification Checklist

- [ ] Downloaded pgAdmin
- [ ] Installed successfully
- [ ] Launched pgAdmin
- [ ] Set master password
- [ ] Added "Canvas Editor DB" server
- [ ] Connected successfully (green icon)
- [ ] Can see 5 tables under canvas_db
- [ ] Viewed data in users table

---

## 🎉 You're All Set!

Once connected, you can:
- ✅ View all database tables
- ✅ Run SQL queries
- ✅ Monitor data changes in real-time
- ✅ Export data
- ✅ View table relationships
- ✅ Analyze database structure

---

## 📚 Next Steps

### After pgAdmin is working:

1. **Test the Frontend**: http://127.0.0.1:56153
   - Register a new user
   - Create a canvas
   - Add widgets
   - Refresh pgAdmin to see the data!

2. **Monitor Real-time**:
   - Keep pgAdmin open
   - Make changes in frontend
   - Refresh table in pgAdmin (F5)
   - Watch data update!

3. **Explore More**:
   - Try the SQL queries above
   - View table relationships
   - Check widget versions
   - Monitor database size

---

## 📞 Need Help?

### Connection Details (copy-paste ready):
```
Host: localhost
Port: 5432
Database: canvas_db
Username: canvas_user
Password: canvas_pass
```

### Files Created:
- `DATABASE_CONNECTION.txt` - Quick reference
- `check-database.js` - Database preview script
- `INSTALL_POSTGRESQL_GUI.md` - Full guide

---

**Happy Database Browsing! 🎉**

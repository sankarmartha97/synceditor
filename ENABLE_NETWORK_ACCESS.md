# Enable Network Access - Quick Guide

## ✅ Current Status

- **Backend:** Running on port 5000 ✅
- **Frontend:** Running on port 8080 ✅
- **Local Access:** Working ✅
- **Network Access:** Needs firewall configuration ⚠️

---

## 🔥 Allow Firewall Access (Required)

### Option 1: Quick Fix (Recommended)

1. **Press Windows Key**
2. **Type:** `Windows Defender Firewall`
3. **Click:** "Windows Defender Firewall with Advanced Security"
4. **Click:** "Inbound Rules" (left side)
5. **Click:** "New Rule..." (right side)
6. **Select:** Port → Next
7. **Select:** TCP
8. **Type:** `8080` in "Specific local ports"
9. **Click:** Next → Allow the connection → Next
10. **Check all:** Domain, Private, Public
11. **Name:** `SyncEditor Frontend`
12. **Click:** Finish

**Repeat for Backend (port 5000):**
- Same steps but use port `5000`
- Name it `SyncEditor Backend`

### Option 2: Run as Administrator (Quick Command)

**Open PowerShell as Administrator** and run:

```powershell
# Allow Frontend (port 8080)
netsh advfirewall firewall add rule name="SyncEditor Frontend" dir=in action=allow protocol=TCP localport=8080

# Allow Backend (port 5000)
netsh advfirewall firewall add rule name="SyncEditor Backend" dir=in action=allow protocol=TCP localport=5000
```

### Option 3: Temporarily Disable Firewall (Not Recommended)

⚠️ **Only for quick testing, not secure!**

1. Open Windows Defender Firewall
2. Click "Turn Windows Defender Firewall on or off"
3. Turn off for Private network only
4. Test, then turn it back on

---

## 🧪 Test Network Access

### Step 1: Test on This Computer First

Open browser and go to:
```
http://localhost:8080
```

**Expected:** You should see the SyncEditor login page ✅

### Step 2: Test Network Access

On **another device** (phone/tablet) connected to same WiFi:

```
http://192.168.1.153:8080
```

**Expected:** You should see the SyncEditor login page ✅

---

## 🔍 Troubleshooting

### Check if Server is Running:

```powershell
netstat -ano | findstr :8080
```

**Expected output:** Something like `0.0.0.0:8080` or `[::]:8080`

### Check if Port is Blocked:

Try from this computer:
```powershell
curl http://192.168.1.153:8080 -I
```

**If it works:** Firewall is NOT the issue  
**If it fails:** Firewall is blocking

### Test Backend:

```
http://192.168.1.153:5000/health
```

**Expected:** `{"status":"ok"}`

---

## 📱 Once Firewall is Configured:

### Access URLs:

**From This Computer:**
- Frontend: http://localhost:8080
- Backend: http://localhost:5000/health

**From Other Devices (Same WiFi):**
- Frontend: http://192.168.1.153:8080
- Backend: http://192.168.1.153:5000/health

---

## ✅ Verification Checklist

- [ ] Windows Firewall rules added for ports 8080 and 5000
- [ ] Can access http://localhost:8080 from this computer
- [ ] Can access http://192.168.1.153:8080 from this computer
- [ ] Can access http://192.168.1.153:8080 from phone/tablet
- [ ] Backend health check works: http://192.168.1.153:5000/health

---

## 🎯 After Firewall is Configured:

Test the cursor fix:

1. **Open on this computer:** http://localhost:8080
2. **Open on phone:** http://192.168.1.153:8080
3. **Login on both devices**
4. **Open same page on both**
5. **Move cursor on computer**
6. **See cursor appear on phone!** ✨

---

## 💡 Alternative: Use Chrome Remote Debugging

If firewall is too restrictive, you can use Chrome's remote debugging:

1. On this computer, open Chrome
2. Go to: chrome://inspect
3. Enable port forwarding
4. Connect via USB to phone

---

**Your IP:** 192.168.1.153  
**Frontend Port:** 8080  
**Backend Port:** 5000  
**Status:** Ready (after firewall configured)

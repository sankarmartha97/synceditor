# SyncEditor - Server Access URLs (Updated)

## 🚀 Servers Running

### Backend Server ✅
**Status:** Running  
**Port:** 5000  
**Network IP:** 192.168.1.153

### Frontend Server ✅
**Status:** Running  
**Port:** 8080  
**Network IP:** 192.168.1.153  
**Configuration:** Using network IP for API calls

---

## 🌐 Access URLs

### 📍 On This Computer (localhost)

**Frontend:**
- http://localhost:8080
- http://127.0.0.1:8080

**Backend API:**
- http://localhost:5000
- http://localhost:5000/health (health check)
- http://localhost:5000/api (API info)

**WebSocket:**
- ws://localhost:5000

---

### 📱 From Other Devices on WiFi

**Your Local IP:** `192.168.1.153`

**Frontend (Mobile/Tablet/Other Computer):**
```
http://192.168.1.153:8080
```

**Backend API:**
```
http://192.168.1.153:5000
```

**WebSocket:**
```
ws://192.168.1.153:5000
```

---

## 🔧 How to Access from Other Devices

### Step 1: Connect to Same WiFi
Make sure the other device is connected to the **same WiFi network** as this computer.

### Step 2: Open Browser
On the other device, open any web browser:
- Chrome
- Safari
- Firefox
- Edge

### Step 3: Enter URL
Type this URL in the address bar:
```
http://192.168.1.153:8080
```

### Step 4: Test
You should see the SyncEditor login page!

---

## 📱 Tested Devices

You can access from:
- ✅ Other computers on WiFi
- ✅ Mobile phones (Android/iOS)
- ✅ Tablets (iPad/Android)
- ✅ Smart TVs with browsers
- ✅ Any device with a web browser on your WiFi

---

## 🧪 Testing Cursor Position Fix

### Test Setup:
1. **Device 1 (This Computer):**
   - Open: http://localhost:8080
   - Login and open a page

2. **Device 2 (Phone/Tablet/Another Computer):**
   - Open: http://192.168.1.153:8080
   - Login with same or different account
   - Open the same page

3. **Test Cursor Sync:**
   - Move cursor on Device 1
   - See cursor appear on Device 2
   - Try zooming in/out on both devices
   - Verify cursor positions match!

---

## 🛠️ Troubleshooting

### Issue: Can't access from other device

**Solution 1: Check Firewall**
Windows Firewall might be blocking port 8080.

Run this command to allow port 8080:
```powershell
New-NetFirewallRule -DisplayName "Flutter Dev Server" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
```

**Solution 2: Verify IP Address**
Make sure you're using the correct IP. Check with:
```powershell
ipconfig
```
Look for "IPv4 Address" under your WiFi adapter.

**Solution 3: Check WiFi Connection**
- Both devices must be on same WiFi network
- Some public WiFi networks block device-to-device connections

**Solution 4: Try Different Browser**
- Try Chrome, Safari, or Firefox
- Clear browser cache if needed

### Issue: Backend not connecting

**Solution 1: Check Backend is Running**
Visit: http://192.168.1.153:5000/health
Should return: `{"status":"ok"}`

**Solution 2: Open Backend Port**
```powershell
New-NetFirewallRule -DisplayName "Node Backend" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

### Issue: WebSocket not connecting

**Check console errors:**
1. Open browser DevTools (F12)
2. Go to Console tab
3. Look for WebSocket connection errors
4. Make sure backend is running

---

## 📊 Server Status

### Check Backend Health:
```
http://192.168.1.153:5000/health
```
Expected response:
```json
{"status":"ok","timestamp":"2026-09-02T..."}
```

### Check Frontend:
```
http://192.168.1.153:8080
```
Should load the login page.

---

## 🔒 Security Notes

### Current Setup (Development):
- ⚠️ No HTTPS (not secure for production)
- ⚠️ No authentication on network level
- ⚠️ Firewall rules opened for development

### For Production:
- ✅ Use HTTPS
- ✅ Use reverse proxy (nginx)
- ✅ Proper firewall configuration
- ✅ VPN for remote access

---

## 📝 Quick Commands

### Stop Servers:
Backend and Frontend are running in background terminals.
- They will stop when you close this IDE
- Or use Ctrl+C in their respective terminals

### Restart Servers:
If you need to restart:

**Backend:**
```powershell
cd backend
npm start
```

**Frontend:**
```powershell
cd frontend
flutter run -d chrome --web-hostname=0.0.0.0 --web-port=8080
```

---

## 🎯 Next Steps

1. ✅ Both servers are running
2. ✅ Accessible from localhost
3. ✅ Accessible from WiFi devices
4. ⏳ Test cursor position fix with multiple devices
5. ⏳ Test zoom/pan synchronization

---

## 📞 Need Help?

If you encounter issues:
1. Check firewall settings
2. Verify both devices on same WiFi
3. Check browser console for errors
4. Restart servers if needed

---

**Server Started:** September 2, 2026  
**IP Address:** 192.168.1.153  
**Frontend Port:** 8080  
**Backend Port:** 5000  
**Status:** ✅ Running

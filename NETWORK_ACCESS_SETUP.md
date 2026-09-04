# Network Access Setup Guide

## Allow Others to Access Your SyncEditor via Your IP Address

### Current Setup
- **Backend**: Running on `http://localhost:5000` → Changed to `http://0.0.0.0:5000`
- **Frontend**: Running on `http://localhost:3000`
- **CORS**: Configured to allow all origins (`*`)

---

## ✅ Changes Made

### 1. Backend Configuration
**File**: `backend/src-js/server.js`
- Changed from `httpServer.listen(config.port)` 
- To: `httpServer.listen(config.port, '0.0.0.0')`
- This allows the backend to accept connections from any network interface

### 2. CORS Configuration
**File**: `backend/.env`
- Changed from: `ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080`
- To: `ALLOWED_ORIGINS=*`
- This allows requests from any origin

**File**: `backend/src-js/app.js`
- Already configured with `origin: '*'`

---

## 🚀 How to Run for Network Access

### Step 1: Find Your IP Address

**On Windows (PowerShell):**
```powershell
ipconfig
```
Look for "IPv4 Address" under your active network adapter (e.g., `192.168.1.100`)

**On Linux/Mac:**
```bash
ifconfig
# or
ip addr show
```

### Step 2: Start Backend Server
```bash
cd backend
npm run dev
```
Backend will be accessible at:
- Local: `http://localhost:5000`
- Network: `http://YOUR_IP:5000` (e.g., `http://192.168.1.100:5000`)

### Step 3: Update Frontend API Configuration

**File**: `frontend/lib/core/api/endpoints.dart`

You need to change the API URL from `localhost` to your actual IP address:

```dart
class ApiEndpoints {
  // Change this to your machine's IP address
  static const String baseUrl = 'http://192.168.1.100:5000';  // <-- YOUR IP HERE
  static const String wsUrl = 'http://192.168.1.100:5000';    // <-- YOUR IP HERE
  
  // ... rest of the file
}
```

### Step 4: Build Flutter Web App
```bash
cd frontend
flutter build web
```

### Step 5: Serve Flutter App on Network
Use a simple HTTP server to serve the built web app:

**Option A: Using Python:**
```bash
cd frontend/build/web
python -m http.server 3000 --bind 0.0.0.0
```

**Option B: Using Node.js http-server:**
```bash
npm install -g http-server
cd frontend/build/web
http-server -p 3000 -a 0.0.0.0 --cors
```

---

## 🌐 Access URLs

### For You (Local Machine):
- Frontend: `http://localhost:3000`
- Backend: `http://localhost:5000`

### For Others on Same Network:
- Frontend: `http://YOUR_IP:3000` (e.g., `http://192.168.1.100:3000`)
- Backend: `http://YOUR_IP:5000` (e.g., `http://192.168.1.100:5000`)

---

## 🔥 Firewall Configuration

### Windows Firewall
You may need to allow incoming connections on ports 3000 and 5000:

**PowerShell (Run as Administrator):**
```powershell
# Allow Backend (port 5000)
New-NetFirewallRule -DisplayName "SyncEditor Backend" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow

# Allow Frontend (port 3000)
New-NetFirewallRule -DisplayName "SyncEditor Frontend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

### Linux (UFW)
```bash
sudo ufw allow 5000/tcp
sudo ufw allow 3000/tcp
```

### Mac
Go to **System Preferences → Security & Privacy → Firewall → Firewall Options**
- Allow incoming connections for your terminal/Node.js

---

## 🔒 Security Notes

### For Development (Current Setup)
- ✅ CORS allows all origins (`*`)
- ✅ Backend listens on all network interfaces (`0.0.0.0`)
- ⚠️ **NOT SECURE FOR PRODUCTION**

### For Production
You should:
1. **Restrict CORS** to specific domains:
   ```
   ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
   ```

2. **Use HTTPS** with SSL certificates

3. **Add Authentication** middleware

4. **Use Environment-Specific Configuration**:
   ```javascript
   const allowedOrigins = process.env.NODE_ENV === 'production'
     ? ['https://yourdomain.com']
     : '*';
   ```

5. **Add Rate Limiting** (already configured)

6. **Use Reverse Proxy** (nginx/Apache) instead of direct Node.js access

---

## 🧪 Testing Network Access

### Step 1: On Your Machine
```bash
# Test backend
curl http://localhost:5000/health

# Should return: {"status":"ok","timestamp":"..."}
```

### Step 2: From Another Device on Same Network
```bash
# Replace 192.168.1.100 with your actual IP
curl http://192.168.1.100:5000/health
```

### Step 3: Open Browser on Another Device
Visit: `http://192.168.1.100:3000`

You should see the SyncEditor login page.

---

## 🐛 Troubleshooting

### Issue: "Connection Refused"
- Check if backend is running: `netstat -an | findstr :5000`
- Check firewall settings
- Verify IP address: `ipconfig`

### Issue: "CORS Error"
- Verify `ALLOWED_ORIGINS=*` in `.env`
- Check browser console for exact error
- Restart backend server after changing `.env`

### Issue: "WebSocket Connection Failed"
- Ensure WebSocket URL in frontend matches backend IP
- Check if port 5000 is open in firewall
- Verify Socket.IO CORS configuration

### Issue: "Cannot Find Server"
- Make sure both devices are on the same network
- Verify IP address with `ipconfig`/`ifconfig`
- Try pinging: `ping 192.168.1.100`

---

## 📝 Quick Start Checklist

- [ ] Backend configured to listen on `0.0.0.0`
- [ ] CORS set to `*` in `.env`
- [ ] Find your IP address (`ipconfig`)
- [ ] Update frontend `endpoints.dart` with your IP
- [ ] Build Flutter web app (`flutter build web`)
- [ ] Start backend (`npm run dev`)
- [ ] Serve frontend (`python -m http.server 3000 --bind 0.0.0.0`)
- [ ] Configure firewall to allow ports 3000 and 5000
- [ ] Test from another device: `http://YOUR_IP:3000`

---

## 🎯 Summary

**Before:** Only accessible on your machine (`localhost`)
**After:** Accessible from any device on your local network via your IP address

**Example:**
- Your IP: `192.168.1.100`
- Anyone on your WiFi can access: `http://192.168.1.100:3000`
- They can collaborate in real-time!

---

## 🚀 Next Steps

1. **For Internet Access**: Use a tunneling service like ngrok, cloudflared, or localtunnel
2. **For Production**: Deploy to a cloud provider (AWS, Google Cloud, Azure, Vercel, etc.)
3. **For Security**: Implement proper authentication and HTTPS


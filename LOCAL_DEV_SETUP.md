# SyncEditor — Local Dev Setup (cmd.exe)

How to start Redis, the backend, and the frontend from a cold Windows machine, plus fixes for what typically goes wrong at each step.

---

## Test login accounts

Two working accounts, registered directly against the live backend (not the unverified `database/seeds/sample_data.sql` — that seed file's password hash didn't actually match `password123` when tested against this database, so these were created fresh via `POST /api/auth/register` instead). Useful for testing two-user collaboration (following, live cursors, comments/mentions) — open one in a normal Chrome window and the other in a second profile/instance (see the two-instance command in Step 4).

| Name | Email | Password |
|---|---|---|
| Alice | `alice@example.com` | `password123` |
| Bob | `bob@example.com` | `password123` |

---

## Step 1 — Start Redis (Memurai)

```cmd
net start Memurai
```

This needs an **elevated (Administrator) Command Prompt** — right-click Command Prompt → "Run as administrator" — otherwise you'll get `Access is denied`.

**If you don't want to open an admin prompt**, run the executable directly instead of going through the service manager:
```cmd
start "" "C:\Program Files\Memurai\memurai.exe"
```
(Note: started this way it won't survive a reboot or relaunch itself — that only happens if it's running as the registered Windows service.)

**Verify it's actually listening:**
```cmd
netstat -ano | findstr :6379
```
If a line comes back with `LISTENING`, it's up. If nothing comes back, it isn't.

**If it still won't start:**

| Symptom | Fix |
|---|---|
| `Access is denied` on `net start` | Open cmd as Administrator, retry |
| `The specified service does not exist` | Find the real service name: `sc query state= all \| findstr /i memurai` (or `redis`) |
| `memurai.exe` not found at that path | Search for it: `where /r "C:\Program Files" memurai.exe` |
| Port 6379 already used by something else | `netstat -ano \| findstr :6379` → note the PID → `tasklist /FI "PID eq <pid>"` to see what it is → `taskkill /PID <pid> /F` to kill it if safe |
| No Redis/Memurai installed at all | Install Memurai (memurai.com), or install Docker Desktop and run `docker run -d -p 6379:6379 redis`, or via WSL: `wsl sudo apt install redis-server` then `wsl redis-server` |

---

## Step 2 — Confirm Postgres is running

```cmd
netstat -ano | findstr :5432
```

If nothing's listening:
```cmd
sc query state= all | findstr /i postgres
```
to find the exact service name (varies by install, e.g. `postgresql-x64-16`), then:
```cmd
net start postgresql-x64-16
```
(admin cmd required). You can also do this via `services.msc` → find the Postgres service → right-click → Start.

**If it's running but the backend still can't connect:** check `backend\.env` — `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` must match your actual Postgres setup. Test directly if `psql` is installed:
```cmd
psql -U canvas_user -d canvas_db -h localhost
```

---

## Step 3 — Start the backend

```cmd
cd /d C:\Users\RedoQ\KuickStudio_Work_Space\SyncEditor\backend
npm install
npm run dev
```
(`npm install` only needed the first time, or after pulling dependency changes.) This runs `nodemon src-js/server.js` — leave the window open, it's the live server.

**Confirm it's healthy** from a second cmd window:
```cmd
curl http://localhost:5000/health
```

**Troubleshooting:**

| Symptom | Fix |
|---|---|
| `EADDRINUSE: address already in use 0.0.0.0:5000` | Something's already on port 5000 — check with `netstat -ano \| findstr :5000`; if it's an old/orphaned instance, `taskkill /PID <pid> /F`. If it's already a healthy running copy of this same backend, don't start a second one — just use it (`curl http://localhost:5000/health` to confirm) |
| `Database connection failed` | Postgres isn't running or `.env` is wrong — see Step 2 |
| `Redis connection failed, continuing without cache` | Not fatal, backend still starts, but presence/cursors/follow mode won't work — fix by completing Step 1 |
| `'npm' is not recognized` | Node.js isn't installed or not on PATH — install from nodejs.org, reopen cmd, verify with `where npm` |
| `Cannot find module '...'` | Dependencies missing — run `npm install` again in `backend\` |
| Repeated crash/restart loop | Read the actual stack trace printed just above the crash — often a bad `.env` value or a missing table (run migrations: `node database/run-migrations.js`) |

---

## Step 4 — Start the frontend

In a **separate** cmd window:
```cmd
cd /d C:\Users\RedoQ\KuickStudio_Work_Space\SyncEditor\frontend
flutter pub get
flutter run -d chrome --web-port=3000 --dart-define=ENVIRONMENT=development --dart-define=API_BASE_URL=http://localhost:5000 --dart-define=WS_URL=ws://localhost:5000 --dart-define=DEBUG=true
```
Chrome opens automatically once it compiles. Leave the window open — it's interactive (`r` = hot reload, `R` = hot restart, `q` = quit).

For a second simultaneous instance (useful for testing two collaborating users), use a different port and a separate Chrome profile, e.g.:
```cmd
flutter run -d chrome --web-port=3001 --dart-define=ENVIRONMENT=development --dart-define=API_BASE_URL=http://localhost:5000 --dart-define=WS_URL=ws://localhost:5000 --dart-define=DEBUG=true --web-browser-flag="--user-data-dir=C:\temp\chrome-profile-3001"
```

**Troubleshooting:**

| Symptom | Fix |
|---|---|
| `'flutter' is not recognized` | Flutter SDK not on PATH — check with `where flutter`; if missing, add the Flutter `bin` folder to PATH and reopen cmd |
| `No connected devices` | Make sure Chrome is installed; check with `flutter devices` |
| Stuck for a long time on "Waiting for connection from debug service on Chrome..." | Usually a locked/stale Chrome profile — close all Chrome windows and retry, or add a fresh profile flag: `--web-browser-flag="--user-data-dir=C:\temp\chrome-profile-3000"` |
| Build errors about missing packages | `flutter pub get` again; if that doesn't fix it, `flutter clean` then `flutter pub get` |
| Port 3000 already in use | Use a different port, e.g. `--web-port=3002`, or free it: `netstat -ano \| findstr :3000` → `taskkill /PID <pid> /F` |
| App loads but every API call fails | Confirm the backend is actually reachable (`curl http://localhost:5000/health`) and that `API_BASE_URL` matches where it's really running |

---

## Order to run everything from a cold start
1. `net start Memurai` (Redis) — admin cmd, or `start "" "C:\Program Files\Memurai\memurai.exe"`
2. Confirm Postgres is running
3. cmd window 1 → `backend` → `npm run dev`
4. cmd window 2 → `frontend` → `flutter run -d chrome ...`

---

## General Windows diagnostic toolkit

| Task | Command |
|---|---|
| What's listening on a port | `netstat -ano \| findstr :<port>` |
| Identify a PID | `tasklist /FI "PID eq <pid>"` |
| Kill a process | `taskkill /PID <pid> /F` |
| Find/list a Windows service | `sc query state= all \| findstr /i <name>` |
| Start a service (admin cmd) | `net start <ServiceName>` |
| Stop a service (admin cmd) | `net stop <ServiceName>` |
| Check if a program is on PATH | `where <program>` |

# Development Quick Start Guide

**For**: Local development with the workout planner
**Script**: `./dev.sh`

---

## Quick Commands

### Most Common (Daily Use)

```bash
# Check if everything is running
./dev.sh status

# After making code changes (FASTEST - use this first)
./dev.sh hot-reload

# If hot-reload doesn't work
./dev.sh hot-restart

# View logs while developing
./dev.sh logs
```

---

## Complete Command Reference

### 📊 Status & Monitoring

```bash
./dev.sh status              # Show service status and health
./dev.sh logs                # Tail both frontend and backend logs
./dev.sh logs frontend       # Tail frontend logs only
./dev.sh logs backend        # Tail backend logs only
```

### ⚡ Quick Reload (Recommended for Development)

```bash
./dev.sh hot-reload          # Fast reload (preserves app state)
./dev.sh hot-restart         # Full restart (resets app state)
```

**When to use each:**
- **hot-reload**: After most code changes (UI tweaks, logic changes)
- **hot-restart**: After adding new files, changing dependencies, or if hot-reload fails

### 🚀 Start Services

```bash
./dev.sh start-all           # Start both frontend and backend
./dev.sh start-frontend      # Start Flutter web app only
./dev.sh start-backend       # Start FastAPI backend only
```

### 🛑 Stop Services

```bash
./dev.sh stop-all            # Stop both services
./dev.sh stop-frontend       # Stop Flutter only
./dev.sh stop-backend        # Stop backend only
```

### 🔄 Restart Services (Full Restart)

```bash
./dev.sh restart-all         # Restart everything
./dev.sh restart-frontend    # Full Flutter restart
./dev.sh restart-backend     # Restart backend
```

**Note:** For frontend, prefer `hot-reload` over `restart-frontend` - it's much faster!

### 🧪 Testing

```bash
./dev.sh test-all            # Run all tests (backend + frontend)
./dev.sh test-frontend       # Run Flutter tests only
./dev.sh test-backend        # Run pytest tests only
```

---

## Typical Workflow

### Starting Your Development Session

```bash
# 1. Check if services are running
./dev.sh status

# 2. If not running, start everything
./dev.sh start-all

# 3. Open your browser to http://localhost:8080
```

### Making Code Changes

```bash
# 1. Edit your code in your editor

# 2. Save the file

# 3. Hot reload to see changes
./dev.sh hot-reload

# 4. If that doesn't work, try hot restart
./dev.sh hot-restart

# 5. If still not working, check logs
./dev.sh logs frontend
```

### Debugging Issues

```bash
# Check service status
./dev.sh status

# View live logs
./dev.sh logs

# Restart everything if needed
./dev.sh restart-all

# Run tests to verify
./dev.sh test-all
```

### Ending Your Development Session

```bash
# Stop all services (optional - you can leave them running)
./dev.sh stop-all
```

---

## Access Points

| Service | URL | Description |
|---------|-----|-------------|
| **Frontend** | http://localhost:8080 | Flutter web app |
| **Backend** | http://localhost:8000 | FastAPI server |
| **API Docs** | http://localhost:8000/docs | Interactive API documentation |
| **Health Check** | http://localhost:8000/healthz | Backend health endpoint |

---

## Log Files

| Service | Log File | Command |
|---------|----------|---------|
| **Frontend** | `/tmp/flutter-workout.log` | `tail -f /tmp/flutter-workout.log` |
| **Backend** | `/tmp/workout-planner.log` | `tail -f /tmp/workout-planner.log` |

**Or use the script:**
```bash
./dev.sh logs frontend    # Frontend logs
./dev.sh logs backend     # Backend logs
./dev.sh logs             # Both logs
```

---

## Troubleshooting

### Frontend Won't Start

```bash
# Check if port 8080 is in use
lsof -i :8080

# Kill any process on port 8080
./dev.sh stop-frontend

# Try starting again
./dev.sh start-frontend

# Check logs for errors
./dev.sh logs frontend
```

### Backend Won't Start

```bash
# Check if port 8000 is in use
lsof -i :8000

# Kill any process on port 8000
./dev.sh stop-backend

# Verify virtual environment exists
ls /home/shawn/_Projects/services/workout-planner/.venv

# Try starting again
./dev.sh start-backend

# Check logs for errors
./dev.sh logs backend
```

### Hot Reload Not Working

```bash
# Try hot restart instead
./dev.sh hot-restart

# If still not working, do a full restart
./dev.sh restart-frontend

# For backend changes, restart backend
./dev.sh restart-backend
```

### Changes Not Appearing

**Frontend changes:**
1. Try hot-reload first: `./dev.sh hot-reload`
2. If not working, try hot-restart: `./dev.sh hot-restart`
3. Last resort - full restart: `./dev.sh restart-frontend`
4. Check browser cache (Ctrl+Shift+R to hard refresh)

**Backend changes:**
- Backend auto-reloads with `--reload` flag
- Check logs: `./dev.sh logs backend`
- If needed: `./dev.sh restart-backend`

### Database Issues

```bash
# Check database file exists
ls -lh /home/shawn/_Projects/services/workout-planner/fitness_dev.db

# Check migration status
cd /home/shawn/_Projects/services/workout-planner
.venv/bin/alembic current

# Apply migrations if needed
.venv/bin/alembic upgrade head
```

---

## Script Shortcuts

The script supports short aliases for common commands:

| Full Command | Aliases |
|--------------|---------|
| `status` | `st` |
| `hot-reload` | `reload`, `hr`, `r` |
| `hot-restart` | `restart-hot`, `hR` |
| `start-all` | `start`, `up` |
| `stop-all` | `stop`, `down` |
| `logs` | `log`, `l` |
| `test-all` | `test` |

**Examples:**
```bash
./dev.sh st              # Same as status
./dev.sh r               # Same as hot-reload
./dev.sh up              # Same as start-all
./dev.sh l frontend      # Same as logs frontend
```

---

## Tips for Efficient Development

1. **Keep services running** - No need to restart between sessions
2. **Use hot-reload** - It's much faster than full restarts
3. **Watch logs** - Run `./dev.sh logs` in a separate terminal
4. **Test frequently** - Run `./dev.sh test-all` before committing
5. **Check status first** - Always run `./dev.sh status` when starting

---

## Related Documentation

- **[CLAUDE.md](./CLAUDE.md)** - Project overview and structure
- **[RUNNING_LOCALLY.md](/home/shawn/_Projects/services/workout-planner/RUNNING_LOCALLY.md)** - Detailed local setup guide
- **[QUICK_START.md](/home/shawn/_Projects/services/workout-planner/QUICK_START.md)** - Backend quick start
- **[DROPDOWN_FIX_SUMMARY.md](./DROPDOWN_FIX_SUMMARY.md)** - Recent fixes and testing info

---

## Need Help?

```bash
# Show full help
./dev.sh help
```

For issues or questions, check:
1. Service logs: `./dev.sh logs`
2. Service status: `./dev.sh status`
3. This guide's troubleshooting section above

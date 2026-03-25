# Development Script - Cheat Sheet

**Quick reference for `./dev.sh` commands**

---

## Essential Commands (Use Daily)

```bash
./dev.sh status          # Check if services are running
./dev.sh hot-reload      # Apply code changes (FAST!)
./dev.sh logs            # View live logs
```

---

## Service Management

### Start/Stop

```bash
./dev.sh start-all       # Start both frontend & backend
./dev.sh stop-all        # Stop both services
./dev.sh restart-all     # Restart everything
```

### Individual Services

```bash
./dev.sh start-frontend  # Start Flutter only
./dev.sh start-backend   # Start FastAPI only
./dev.sh stop-frontend   # Stop Flutter
./dev.sh stop-backend    # Stop backend
```

---

## Reloading (Frontend)

```bash
./dev.sh hot-reload      # Fast reload (preserves state) ⚡
./dev.sh hot-restart     # Full restart (resets state)
./dev.sh restart-frontend  # Complete restart (slowest)
```

**When to use:**
- **hot-reload**: After most code changes (UI, logic) - **USE THIS FIRST!**
- **hot-restart**: If hot-reload doesn't work
- **restart-frontend**: Last resort or after dependency changes

---

## Logs

```bash
./dev.sh logs            # Both services
./dev.sh logs frontend   # Frontend only
./dev.sh logs backend    # Backend only
```

**Tip**: Run in separate terminal to monitor while developing

---

## Testing

```bash
./dev.sh test-all        # Run all tests
./dev.sh test-frontend   # Flutter tests only
./dev.sh test-backend    # Pytest only
```

---

## Shortcuts (Save Keystrokes!)

```bash
./dev.sh st              # status
./dev.sh r               # hot-reload
./dev.sh l               # logs
./dev.sh up              # start-all
./dev.sh down            # stop-all
```

---

## Access Points

| What | URL |
|------|-----|
| Frontend | http://localhost:8080 |
| Backend | http://localhost:8000 |
| API Docs | http://localhost:8000/docs |

---

## Troubleshooting

### Changes not appearing?
```bash
./dev.sh hot-reload      # Try this first
./dev.sh hot-restart     # Then this
./dev.sh restart-frontend # Last resort
```

### Service won't start?
```bash
./dev.sh status          # Check what's running
./dev.sh logs frontend   # Check for errors
./dev.sh stop-all        # Clean stop
./dev.sh start-all       # Fresh start
```

### Need to debug?
```bash
./dev.sh logs | grep -i error  # Find errors
./dev.sh status                # Check health
```

---

## Typical Workflow

```bash
# Morning - Start work
./dev.sh status          # Check everything is running

# During development
# ... edit code in editor ...
./dev.sh hot-reload      # See changes (2 seconds!)

# Before committing
./dev.sh test-all        # Run all tests

# End of day (optional)
./dev.sh stop-all        # Or just leave running
```

---

## More Help

```bash
./dev.sh help            # Full help
cat DEV_QUICK_START.md   # Complete guide
cat DEV_SCRIPT_README.md # Technical details
```

---

**Remember**: Hot reload is your friend! Use it often. ⚡

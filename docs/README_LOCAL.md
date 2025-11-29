Local development quickstart

This file explains how to bring up the full local stack for the Fitness Agent project:
- Postgres (via `docker compose`)
- Adminer UI
- Run DB migrations
- Start FastAPI backend
- Build and serve Flutter web frontend (optional)

Prerequisites
- Docker (and docker-compose or Docker CLI plugin)
- Python 3.8+ and `venv` module
- Optional: Flutter SDK to run the frontend in development mode

1) Start services

From the repository root. If you use Docker:

```sh
docker compose -f docker-compose.local.yml up -d
```

Or, if you use Podman (Fedora) with `podman compose` or `podman-compose`:

```sh
podman compose -f docker-compose.local.yml up -d
# or, if you have podman-compose installed:
podman-compose -f docker-compose.local.yml up -d
```

2) Run the helper (recommended)

Make the helper executable and run it:

```sh
chmod +x scripts/run_local.sh
./scripts/run_local.sh
```

The helper does:
- waits for Postgres to become ready
- runs `scripts/run_migrations.sh` (applies SQL files in `database/sql/` and Alembic if configured)
- starts the FastAPI backend (inside `.venv_local`) and logs to `logs/backend.log`
- attempts to build the Flutter web app and serves it on `http://localhost:38541` (if `flutter` is installed)

3) Manual alternatives

- Run migrations manually:

```sh
DATABASE_URL=postgres://postgres:postgres@localhost:5432/fitness_dev ./scripts/run_migrations.sh
```

- Start backend manually:

```sh
python3 -m venv .venv
. .venv/bin/activate
pip install -r applications/backend/fastapi_server/requirements.txt
uvicorn applications.backend.fastapi_server.main:app --reload --host 0.0.0.0 --port 8000
```

- Start Flutter frontend manually (requires Flutter):

```sh
cd applications/frontend/apps/mobile_app
flutter pub get
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=38541
```

4) Stop local services

```sh
docker compose -f docker-compose.local.yml down
```

Notes and troubleshooting
- If you don't have `psql` available, `scripts/run_migrations.sh` will try to apply SQL files inside the running Postgres container (looks for image `postgres:15`).
- If the helper cannot find Postgres, ensure Docker started and the `db` service is running.
- Logs are written under `logs/` (created by the helper script). If a service fails, inspect those logs.

If you want, I can also:
- Add a systemd service or tmux wrapper for background processes.
- Make the helper create `logs/` dir and rotate logs.

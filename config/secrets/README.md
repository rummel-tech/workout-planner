Centralized Secrets

This folder holds example templates for all secrets used in the project. Keep real values ONLY in non-tracked `*.env` files here, and sync to appropriate destinations.

Files
- `ci.secrets.example.env` → Copy to `ci.secrets.env`. Source of truth for GitHub Actions secrets (Apple signing, App Store Connect, AWS, etc.).
- `local.example.env` → Copy to `local.env`. Used for local development (API endpoints, DB, third-party API keys).

Usage
1) Local development
```sh
cp config/secrets/local.example.env config/secrets/local.env
$EDITOR config/secrets/local.env
# Recommended: auto-load with direnv (see below)
direnv allow
```

2) CI (GitHub Actions)
```sh
cp config/secrets/ci.secrets.example.env config/secrets/ci.secrets.env
$EDITOR config/secrets/ci.secrets.env
./scripts/sync_github_secrets.sh <owner/repo>
```

Backend auto-load
- The FastAPI server tries to load `.env` and then `config/secrets/local.env` automatically on startup (using python-dotenv), so environment variables in `local.env` take precedence for local runs.
- You can override the path by setting `SECRETS_ENV_PATH` to any `.env` file. If set, that file is loaded instead of the default.

direnv (auto-loading)
- Install direnv and enable it for your shell (follow https://direnv.net/)
- At the repo root, `.envrc` will:
	- Load `SECRETS_ENV_PATH` if it points to a file
	- Otherwise load `config/secrets/local.env` if present
- Quickstart:
```sh
sudo apt-get install direnv # or brew install direnv
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc  # adjust for your shell
direnv allow
```
- To use a custom env file:
```sh
export SECRETS_ENV_PATH=/absolute/path/to/your.env
direnv reload
```

Security
- `config/secrets/*.env` is ignored by git. Do not commit real secrets.
- Consider migrating to Vault later; the same file format can be generated from Vault and re-used with the sync script.

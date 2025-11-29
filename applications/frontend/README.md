**Proposed Frontend Layout**

- `frontend/`
  - `apps/` — place runnable Flutter apps (e.g. `mobile_app/`)
  - `packages/` — reusable Dart packages (theme, widgets, navigation)
  - `legacy_ui/` — copied UI modules from repo root for inspection and migration
  - `scripts/` — frontend helper scripts

What I created
- `frontend/legacy_ui/` (empty placeholder) — target for copied modules
- `scripts/consolidate_frontend.sh` — safe copy script (dry-run supported)

Recommended next steps
1. Run a dry-run to verify which folders will be copied:

```sh
sh scripts/consolidate_frontend.sh --dry-run
```

2. If output looks correct, run the actual copy:

```sh
sh scripts/consolidate_frontend.sh
```

3. Create a single Flutter app under `frontend/apps/mobile_app` and move shared UI into `frontend/packages/*` as path dependencies in its `pubspec.yaml`.

4. Update imports in the copied modules to use package-style imports or relative imports under the new structure.

5. Run `flutter analyze` and `flutter test` to find and fix issues.

6. Add CI job to build the Flutter app and publish artifacts.

Notes
- I did NOT delete or modify original source folders. This is a safe consolidation plan — run the script to copy them into `frontend/legacy_ui` and then proceed with migration.
- If you want I can create a starter `frontend/apps/mobile_app` with a minimal `pubspec.yaml` and `lib/main.dart` wired to the theme package next.

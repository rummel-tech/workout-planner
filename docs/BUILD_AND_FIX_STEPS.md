# Build and Fix Steps for Flutter Web

## Quick Fix (Build Immediately)

The freezed-generated files are missing. I've replaced the `freezed` model with a simpler non-freezed version in `packages/goals_ui/lib/ui_components/goal_model.dart`. This lets you build now without waiting for code generation.

**Just rebuild:**

```bash
cd applications/frontend/apps/mobile_app
flutter pub get
flutter build web
# or for dev:
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=38541
```

The app should build and run successfully now.

---

## Optional: Switch Back to Freezed (for Type Safety & JSON Serialization)

If you prefer the freezed version (better for JSON serialization and immutability), follow these steps:

### 1) Run Code Generation

```bash
cd applications/frontend
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates:
- `packages/goals_ui/lib/ui_components/goal_model.freezed.dart`
- `packages/goals_ui/lib/ui_components/goal_model.g.dart`

### 2) Switch goal_model.dart Back to Freezed

Uncomment the freezed version in `goal_model.dart` and comment out (or remove) the simple version. Then rebuild:

```bash
cd applications/frontend/apps/mobile_app
flutter pub get
flutter build web
```

---

## (Optional) Remove flutter_local_notifications

If you're running web and don't need notifications, remove the dependency:

```bash
cd applications/frontend/apps/mobile_app
flutter pub remove flutter_local_notifications
```

Or manually edit `pubspec.yaml` and remove any line referencing `flutter_local_notifications`.

---

## Troubleshooting

- **Build still fails?** Ensure you're in the correct directory and have run `flutter pub get` first.
- **Slow build_runner?** Use `--delete-conflicting-outputs` or delete `.dart_tool` and try again.
- **Still seeing errors?** Try `flutter clean && flutter pub get && flutter pub run build_runner build`.
- **Freezed not working?** Make sure `freezed`, `build_runner`, and `json_serializable` are in `pubspec.yaml` dev_dependencies.




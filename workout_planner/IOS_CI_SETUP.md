# iOS CI Signed Build Setup (GitHub Actions)

This guide helps you produce a signed iOS IPA from GitHub Actions using the provided workflow: `.github/workflows/ios-signed-build.yml`.

## Prerequisites

- Apple Developer account (Individual or Company)
- An iOS Distribution or Development certificate exported as `.p12`
- A Provisioning Profile (`.mobileprovision`)
  - For direct device installs, use an Ad‑Hoc profile (add device UDIDs)
  - For TestFlight, use an App Store profile and (optionally) App Store Connect API credentials
- Bundle Identifier in Xcode matches the App ID in your provisioning profile

## 1) Export your certificate (.p12)

On a Mac with your Apple signing certificate in Keychain Access:

1. Open Keychain Access → My Certificates
2. Right‑click the iOS Distribution/Development certificate → Export…
3. Choose `.p12` and set a password (save this password; used as `P12_PASSWORD`)

Base64‑encode the `.p12` (for GitHub Secret):

```sh
base64 -i your_cert.p12 | pbcopy    # copies base64 to clipboard
```

## 2) Download provisioning profile (.mobileprovision)

From Apple Developer portal → Certificates, Identifiers & Profiles → Profiles:

1. Create or download the matching profile for your Bundle ID
2. For Ad‑Hoc: add device UDIDs under Devices → include them in the profile
3. Download the `.mobileprovision`

Base64‑encode it:

```sh
base64 -i your_profile.mobileprovision | pbcopy
```

## 3) Add GitHub Actions Secrets (centralized)

Preferred: keep all CI secrets in one file, then sync to GitHub with the provided script.

1. Copy the template and fill values:

```sh
cp config/secrets/ci.secrets.example.env config/secrets/ci.secrets.env
$EDITOR config/secrets/ci.secrets.env
```

2. Push them to GitHub Actions using gh CLI (ensure `gh auth login`):

```sh
./scripts/sync_github_secrets.sh yourname/fitness-agent
```

Alternatively, add manually in GitHub: Settings → Secrets and variables → Actions → New repository secret.

- `P12_BASE64` → base64 of the `.p12`
- `P12_PASSWORD` → password you used when exporting `.p12`
- `MOBILEPROVISION_BASE64` → base64 of `.mobileprovision`
- `KEYCHAIN_PASSWORD` → any random string (used to create ephemeral CI keychain)

Optional (for TestFlight uploads):

- `APP_STORE_CONNECT_API_KEY` → the RAW contents of your `.p8` API key file (paste entire key including BEGIN/END lines)
- `APP_STORE_CONNECT_ISSUER_ID` → Issuer ID from App Store Connect
- `APP_STORE_CONNECT_KEY_ID` → Key ID from App Store Connect

## 4) Bundle Identifier & Signing

Ensure your Xcode project (Runner target) uses a Bundle Identifier matching the App ID in your provisioning profile:

- Open `applications/frontend/apps/mobile_app/ios/Runner.xcodeproj` (or `Runner.xcworkspace`)
- Target Runner → Signing & Capabilities
- Set Bundle Identifier (e.g., `com.yourdomain.fitnessagent`)
- Commit changes to the repo

The workflow imports the certificate and profile, then archives with:

```
CODE_SIGN_STYLE=Manual
PROVISIONING_PROFILE_SPECIFIER=<UUID extracted from profile>
```

If your build requires a specific development team or code sign identity, add these to the `xcodebuild` step:

```
DEVELOPMENT_TEAM=YOURTEAMID CODE_SIGN_IDENTITY="Apple Distribution"
```

## 5) Run the Workflow

In GitHub → Actions → "iOS Signed Build (Scaffold)" → Run workflow

Artifacts:

- Download the generated `.ipa` attachment from the workflow run (artifact `ios-ipa`).

Install options:

- Ad‑Hoc IPA: Install via Apple Configurator 2 or tools like Diawi (profile must include your device UDID)
- TestFlight: Use App Store profile and upload (fastlane or Xcode Transporter)

## 6) Optional: TestFlight Upload

If you provided the App Store Connect API secrets above, the workflow will automatically upload the exported IPA to TestFlight using `fastlane pilot`.

Alternatively, use Xcode Transporter:

1. Open Transporter on Mac
2. Sign in to App Store Connect
3. Drag the `.ipa` and upload

After processing, invite your Apple ID to TestFlight.

---

Troubleshooting:

- Provisioning error: Ensure the Bundle ID matches exactly and the profile type (Ad‑Hoc vs App Store) fits your target
- Missing entitlements: HealthKit entitlements are included in `Runner.entitlements`; confirm the capability is enabled in Xcode when you build locally
- Build fails at archive: Review the Xcode log in the workflow, confirm `DEVELOPMENT_TEAM` or `CODE_SIGN_IDENTITY` if needed

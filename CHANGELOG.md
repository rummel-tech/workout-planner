# Changelog — Workout Planner

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

---

## [Unreleased]

### Planned
- Artemis platform integration (`/artemis/manifest` endpoint)
- Persistent PostgreSQL backend
- Shared Artemis auth service integration
- Push notifications

---

## [0.3.0] - 2026-01-23

### Added
- `dev.sh` development script: hot-reload, status, log tailing, test running
- AI coach chat interface for fitness guidance
- Weekly plan day ordering fix (Mon–Sun sequence)

### Fixed
- Dropdown validation: workout type case mismatch (`"rest"` vs `"Rest"`) normalised
- Bottom navigation overflow on smaller screens
- Bottom navigation state not persisting on tab switch
- Login JSON parse error on unexpected backend response

### Changed
- Development docs consolidated into `docs/DEVELOPMENT.md`
- Removed session/fix summary files from repo root

---

## [0.2.0] - 2025-12-15

### Added
- Apple HealthKit integration (iOS/macOS) for readiness score
- Readiness score display on dashboard
- AI insights panel
- Settings and profile screens

### Fixed
- iOS CI signed build workflow
- API URL configuration priority order

---

## [0.1.0] - 2025-11-01

### Added
- Weekly workout planning — 7-day calendar view
- Max 3 workouts per day enforced
- Workout detail editor: warmup / main set / cooldown
- Structured exercise fields: sets, reps, weight, duration, distance, rest
- Workout types: Strength, Run, Swim, Murph, Bike, Yoga, Cardio, Mobility, Rest
- Goal creation and workout–goal association
- Authentication: email/password and Google OAuth
- Dashboard with daily overview
- Feature package architecture
- Shared design system via `rummel_blue_theme`

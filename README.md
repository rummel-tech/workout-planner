# Workout Planner

An AI-powered fitness coaching platform with HealthKit integration, readiness scoring, and personalized workout planning.

## Overview

The application provides a planning tool to plan a week's worth of workouts. It associates those workouts with goals and helps you stay on track of your activities. The dashboard displays an overview of the day: health metrics and scheduled workouts. The dashboard also provides navigation to the user's profile, security credentials, and other user-specific data. The weekly view shows the next 7 days of activities, with each day supporting up to 3 workouts.

## Features

### Dashboard
- Daily overview with health metrics and scheduled workouts
- Quick access to today's workout details
- Navigation to profile and settings
- Readiness score display based on health data

### Weekly Planner
- 7-day calendar view of scheduled workouts
- Maximum 3 workouts per day
- Day-level editing with title, focus, description, and time goals
- Link workouts to user goals

### Workout Management
- Full workout detail editor with warmup, main set, and cooldown sections
- Structured exercise tracking (sets, reps, weight, duration, distance, rest)
- Support for multiple workout types: Strength, Run, Swim, Murph, Bike, Yoga, Cardio, Mobility, Rest
- Edit existing workouts or create new ones

### Goals
- Create and manage fitness goals
- Associate workouts with specific goals
- Track progress toward goals

### Authentication
- Email/password login and registration
- Google Sign-In (OAuth 2.0)
- Password reset via email
- Secure token storage with auto-refresh

### Health Integration
- Apple HealthKit integration (iOS/macOS only)
- Sync health metrics to inform readiness scores
- Note: Currently only Apple platforms are supported

### AI Coach
- Chat interface for fitness guidance
- AI-powered workout recommendations
- Personalized insights based on user data

## Implemented Requirements

- [x] Weekly workout planning with 7-day view
- [x] Maximum 3 workouts per day (enforced)
- [x] Workout detail page with exercise builder (warmup/main/cooldown)
- [x] Structured exercise fields (name, sets, reps, weight, duration, distance, rest)
- [x] Goal creation and workout-goal association
- [x] User authentication (email/password and Google OAuth)
- [x] Dashboard with daily overview
- [x] Readiness score display
- [x] Profile and settings screens

## Documentation

- [Development Guide](docs/DEVELOPMENT.md) - Setup, building, testing, and deployment
- [Architecture](docs/ARCHITECTURE.md) - System design and component overview
- [Health Integration](docs/HEALTH_INTEGRATION.md) - Apple HealthKit setup
- [Documentation Index](docs/INDEX.md) - Full documentation listing
- [Changelog](./CHANGELOG.md) - Version history

---

[Platform Documentation](../../../docs/) | [Product Overview](../../../docs/products/workout-planner.md)

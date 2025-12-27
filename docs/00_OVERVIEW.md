# Workout Planner - Overview

**Version:** 1.0
**Last Updated:** 2024-12-24

---

## Executive Summary

**Workout Planner** is an AI-powered fitness coaching platform that helps users plan workouts, track health metrics, set fitness goals, and receive personalized AI coaching. The platform consists of a cross-platform Flutter mobile/web application and a FastAPI backend service.

## Vision Statement

To provide a comprehensive, AI-powered fitness platform that adapts to each user's unique physiology and goals, enabling smarter training decisions through data-driven insights.

## Key Value Propositions

| Value | Description |
|-------|-------------|
| **Intelligent Workout Planning** | AI-driven daily and weekly workout generation based on readiness scores |
| **Health Data Integration** | Syncs with Apple HealthKit for comprehensive health tracking |
| **Personalized AI Coach** | Context-aware chat assistant that understands user's goals and health status |
| **Readiness-Based Training** | Adjusts workout intensity based on HRV, sleep, and recovery metrics |
| **Goal Tracking** | Set and monitor progress toward specific fitness objectives |

## Target Platforms

| Platform | Status | Technology |
|----------|--------|------------|
| iOS | Supported | Flutter |
| Android | Supported | Flutter |
| Web | Supported | Flutter Web |
| macOS | Supported | Flutter Desktop |
| Linux | Supported | Flutter Desktop |

## Core Features

1. **Authentication & Onboarding** - Secure login with registration code system
2. **Home Dashboard** - Daily overview with readiness score and workout preview
3. **Weekly Planning** - 7-day workout schedule with customization
4. **Goal Management** - Create and track fitness goals
5. **Health Metrics Logging** - Manual entry for HRV, sleep, strength, swim data
6. **AI Coach Chat** - Conversational fitness assistant
7. **HealthKit Integration** - Automatic health data sync (iOS/macOS)

## Technology Stack

### Frontend
- **Framework:** Flutter 3.x
- **Language:** Dart
- **State Management:** StatefulWidget + Services
- **Storage:** SharedPreferences, flutter_secure_storage
- **Health Integration:** HealthKit (iOS/macOS)

### Backend
- **Framework:** FastAPI
- **Language:** Python 3.11+
- **Database:** PostgreSQL (production), SQLite (development)
- **Caching:** Redis
- **AI Providers:** OpenAI, Anthropic Claude

## Documentation Index

| Document | Description |
|----------|-------------|
| [01_ARCHITECTURE.md](01_ARCHITECTURE.md) | System architecture and component diagrams |
| [02_DATA_MODELS.md](02_DATA_MODELS.md) | Database schemas and data structures |
| [03_API_SPECIFICATION.md](03_API_SPECIFICATION.md) | REST API endpoint documentation |
| [04_UI_SPECIFICATION.md](04_UI_SPECIFICATION.md) | User interface and navigation specs |
| [05_SECURITY.md](05_SECURITY.md) | Security architecture and requirements |
| [06_INTEGRATIONS.md](06_INTEGRATIONS.md) | External service integrations |
| [07_PERSONAS.md](07_PERSONAS.md) | User personas and test scenarios |
| [requirements.yaml](requirements.yaml) | All functional and non-functional requirements |

## Repository Structure

```
workout-planner/           # Flutter frontend
├── lib/                   # Main application code
├── packages/              # Feature packages
├── docs/                  # This documentation
└── test/                  # Unit tests

services/workout-planner/  # FastAPI backend (separate repo)
├── main.py               # Application entry
├── routers/              # API route handlers
├── database.py           # Database models
└── tests/                # API tests
```

## Quick Start

### Backend
```bash
cd services/workout-planner
source .venv/bin/activate
export DATABASE_URL=sqlite:///fitness_dev.db
uvicorn main:app --reload --port 8000
```

### Frontend
```bash
cd workout-planner
flutter pub get
flutter run -d chrome
```

## Contact & Resources

- **Backend API Docs:** http://localhost:8000/docs
- **Health Endpoint:** http://localhost:8000/health
- **Metrics:** http://localhost:8000/metrics

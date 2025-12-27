# Workout Planner Documentation

This folder contains comprehensive documentation for the Workout Planner platform.

## Documentation Structure

Files are prefixed with numbers for reading order - start with overview, then drill down into details.

### Core Documentation (Read in Order)

| Document | Description |
|----------|-------------|
| [00_OVERVIEW.md](00_OVERVIEW.md) | Executive summary, vision, and quick start |
| [01_ARCHITECTURE.md](01_ARCHITECTURE.md) | System architecture, component diagrams |
| [02_DATA_MODELS.md](02_DATA_MODELS.md) | Database schemas and data structures |
| [03_API_SPECIFICATION.md](03_API_SPECIFICATION.md) | REST API endpoint documentation |
| [04_UI_SPECIFICATION.md](04_UI_SPECIFICATION.md) | User interface and navigation specs |
| [05_SECURITY.md](05_SECURITY.md) | Security architecture and requirements |
| [06_INTEGRATIONS.md](06_INTEGRATIONS.md) | External service integrations |
| [07_PERSONAS.md](07_PERSONAS.md) | User personas and test scenarios |

### Requirements

| Document | Description |
|----------|-------------|
| [requirements.yaml](requirements.yaml) | All functional and non-functional requirements in YAML format |

### Development Guides

| Document | Description |
|----------|-------------|
| [DEVELOPMENT.md](DEVELOPMENT.md) | Development setup and workflows |
| [IOS_BUILD_GUIDE.md](IOS_BUILD_GUIDE.md) | iOS build and deployment |
| [HEALTH_INTEGRATION.md](HEALTH_INTEGRATION.md) | HealthKit integration details |

### Reference

| Document | Description |
|----------|-------------|
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Quick reference for common tasks |
| [STRUCTURE.md](STRUCTURE.md) | Project structure overview |
| [NAVIGATION_AND_FORMS.md](NAVIGATION_AND_FORMS.md) | Navigation and form patterns |

## Quick Links

- **Main README:** [../README.md](../README.md)
- **Backend Docs:** http://localhost:8000/docs (when running)
- **API Health:** http://localhost:8000/health

## For New Developers

1. Start with [00_OVERVIEW.md](00_OVERVIEW.md) to understand the project
2. Read [01_ARCHITECTURE.md](01_ARCHITECTURE.md) for system design
3. Check [DEVELOPMENT.md](DEVELOPMENT.md) for setup instructions
4. Review [requirements.yaml](requirements.yaml) for feature requirements

## For Testers

1. Read [07_PERSONAS.md](07_PERSONAS.md) for user personas and test scenarios
2. Review [requirements.yaml](requirements.yaml) for acceptance criteria
3. Check [03_API_SPECIFICATION.md](03_API_SPECIFICATION.md) for API testing

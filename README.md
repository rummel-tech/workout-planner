# Workout Planner

> AI-powered fitness coaching platform with HealthKit integration, readiness scoring, and personalized workout planning.

## 📖 Documentation

### App-Specific Documentation
- **[Getting Started](./docs/README.md)** - Setup and installation
- **[Architecture](./docs/ARCHITECTURE.md)** - System design and deployment
- **[API Reference](./docs/QUICK_REFERENCE.md)** - Commands and endpoints
- **[Testing Guide](./docs/TESTING.md)** - Running tests and coverage
- **[Documentation Index](./docs/INDEX.md)** - Complete documentation overview

### Platform Documentation (Central Repository)
- **[📚 Documentation Home](https://github.com/srummel/documentation)** - Central platform documentation
- **[🏗️ Multi-App Architecture](https://github.com/srummel/documentation/blob/main/architecture/multi-app-architecture.md)** - How apps coexist
- **[🚀 Deployment](https://github.com/srummel/documentation/blob/main/deployment/)** - Production deployment guides
- **[✅ Best Practices](https://github.com/srummel/documentation/blob/main/best-practices/)** - Platform conventions
- **[📖 References](https://github.com/srummel/documentation/blob/main/references/)** - Port allocation, tech stack

## 🚀 Quick Start

### Backend
```bash
cd applications/backend/python_fastapi_server
pip install -r requirements.txt
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend
```bash
cd applications/frontend/apps/mobile_app
flutter pub get
flutter run
```

## 📂 Project Structure

```
├── docs/                          # All project documentation
├── applications/
│   ├── backend/
│   │   └── python_fastapi_server/ # FastAPI backend with AI engine
│   └── frontend/
│       ├── apps/mobile_app/       # Flutter mobile application
│       └── packages/              # Reusable Flutter packages
├── integrations/
│   └── swift_healthkit_module/    # HealthKit native integration
└── sql/                           # Database schemas and migrations
```

For detailed project structure, see [`docs/STRUCTURE.md`](./docs/STRUCTURE.md).

## 🧪 Testing

```bash
# Backend tests
cd applications/backend/python_fastapi_server
pytest --cov

# Frontend tests  
cd applications/frontend/apps/mobile_app
flutter test
```

See [`docs/TESTING.md`](./docs/TESTING.md) for comprehensive testing guide.

## 🏗️ CI/CD

GitHub Actions workflow runs automated tests, coverage reporting, and artifact storage on every push. See [`.github/workflows/ci.yml`](./.github/workflows/ci.yml).

## 📝 License

See individual package licenses in their respective directories.

---

**For complete documentation, browse the [`docs/`](./docs/) directory or see [`docs/INDEX.md`](./docs/INDEX.md).**

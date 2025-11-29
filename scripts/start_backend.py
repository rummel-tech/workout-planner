#!/usr/bin/env python3
"""
Simple backend starter without database dependency.
Uses in-memory storage for development when database is not available.
"""
import os
import sys

# Add the backend directory to the path
backend_dir = os.path.join(os.path.dirname(__file__), '..', 'applications', 'backend', 'python_fastapi_server')
sys.path.insert(0, backend_dir)

# Set a dummy DATABASE_URL if not set (will fail gracefully)
if 'DATABASE_URL' not in os.environ:
    print("WARNING: DATABASE_URL not set. Database operations will fail.")
    print("To use the database, run: export DATABASE_URL='postgresql://user:pass@localhost:5432/dbname'")
    os.environ['DATABASE_URL'] = 'postgresql://postgres:postgres@localhost:5432/fitness_dev'

if __name__ == '__main__':
    import uvicorn
    print(f"\n🚀 Starting FastAPI backend on http://localhost:8000")
    print(f"📁 Backend directory: {backend_dir}\n")
    
    os.chdir(backend_dir)
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )

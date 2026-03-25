#!/bin/bash

# Workout Planner - Local Development Management Script
# Usage: ./dev.sh [command]

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
FRONTEND_DIR="/home/shawn/_Projects/modules/planners/workout-planner"
BACKEND_DIR="/home/shawn/_Projects/services/workout-planner"
FRONTEND_LOG="/tmp/flutter-workout.log"
BACKEND_LOG="/tmp/workout-planner.log"

# Print colored message
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}\n"
}

# Get process IDs
get_flutter_pid() {
    pgrep -f "flutter.*run.*chrome.*8080" | head -1
}

get_backend_pid() {
    pgrep -f "uvicorn.*main:app.*8000" | head -1
}

# Check if services are running
check_status() {
    print_header "Service Status"

    # Check Flutter
    FLUTTER_PID=$(get_flutter_pid)
    if [ -n "$FLUTTER_PID" ]; then
        print_success "Frontend: Running (PID: $FLUTTER_PID)"
        echo "           URL: http://localhost:8080"
        echo "           Log: $FRONTEND_LOG"
    else
        print_error "Frontend: Not running"
    fi

    echo ""

    # Check Backend
    BACKEND_PID=$(get_backend_pid)
    if [ -n "$BACKEND_PID" ]; then
        print_success "Backend:  Running (PID: $BACKEND_PID)"
        echo "           URL: http://localhost:8000"
        echo "           API Docs: http://localhost:8000/docs"
        echo "           Log: $BACKEND_LOG"
    else
        print_error "Backend:  Not running"
    fi

    echo ""

    # Quick health checks
    if [ -n "$BACKEND_PID" ]; then
        if curl -s http://localhost:8000/healthz > /dev/null 2>&1; then
            print_success "Backend health check: OK"
        else
            print_warning "Backend health check: Failed"
        fi
    fi

    if [ -n "$FLUTTER_PID" ]; then
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
            print_success "Frontend health check: OK"
        else
            print_warning "Frontend health check: Failed"
        fi
    fi
}

# Hot reload Flutter (faster, preserves state)
hot_reload() {
    print_header "Hot Reload Frontend"

    FLUTTER_PID=$(get_flutter_pid)
    if [ -z "$FLUTTER_PID" ]; then
        print_error "Flutter is not running. Use 'start-frontend' first."
        exit 1
    fi

    print_info "Sending hot reload signal to Flutter (PID: $FLUTTER_PID)..."
    kill -USR1 $FLUTTER_PID

    # Wait a moment and check logs
    sleep 2
    print_success "Hot reload triggered"
    echo ""
    tail -5 $FRONTEND_LOG | grep -i "reload\|restarted" || echo "Check logs for reload status"
}

# Hot restart Flutter (slower, resets state)
hot_restart() {
    print_header "Hot Restart Frontend"

    FLUTTER_PID=$(get_flutter_pid)
    if [ -z "$FLUTTER_PID" ]; then
        print_error "Flutter is not running. Use 'start-frontend' first."
        exit 1
    fi

    print_info "Sending hot restart signal to Flutter (PID: $FLUTTER_PID)..."
    kill -USR2 $FLUTTER_PID

    # Wait a moment and check logs
    sleep 3
    print_success "Hot restart triggered"
    echo ""
    tail -5 $FRONTEND_LOG | grep -i "restart\|restarted" || echo "Check logs for restart status"
}

# Stop frontend
stop_frontend() {
    print_header "Stop Frontend"

    FLUTTER_PID=$(get_flutter_pid)
    if [ -z "$FLUTTER_PID" ]; then
        print_warning "Frontend is not running"
        return
    fi

    print_info "Stopping Flutter (PID: $FLUTTER_PID)..."
    kill $FLUTTER_PID 2>/dev/null || true

    # Wait for graceful shutdown
    sleep 2

    # Force kill if still running
    if ps -p $FLUTTER_PID > /dev/null 2>&1; then
        print_warning "Forcing shutdown..."
        kill -9 $FLUTTER_PID 2>/dev/null || true
    fi

    print_success "Frontend stopped"
}

# Stop backend
stop_backend() {
    print_header "Stop Backend"

    BACKEND_PID=$(get_backend_pid)
    if [ -z "$BACKEND_PID" ]; then
        print_warning "Backend is not running"
        return
    fi

    print_info "Stopping backend (PID: $BACKEND_PID)..."
    kill $BACKEND_PID 2>/dev/null || true

    # Wait for graceful shutdown
    sleep 2

    # Force kill if still running
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        print_warning "Forcing shutdown..."
        kill -9 $BACKEND_PID 2>/dev/null || true
    fi

    print_success "Backend stopped"
}

# Start frontend
start_frontend() {
    print_header "Start Frontend"

    FLUTTER_PID=$(get_flutter_pid)
    if [ -n "$FLUTTER_PID" ]; then
        print_warning "Frontend is already running (PID: $FLUTTER_PID)"
        print_info "Use 'hot-reload' or 'hot-restart' to reload code changes"
        return
    fi

    print_info "Starting Flutter web app on port 8080..."
    cd $FRONTEND_DIR

    # Clear old log
    > $FRONTEND_LOG

    # Start Flutter in background
    nohup flutter run -d chrome --web-port 8080 > $FRONTEND_LOG 2>&1 &

    print_info "Waiting for Flutter to start..."
    sleep 5

    FLUTTER_PID=$(get_flutter_pid)
    if [ -n "$FLUTTER_PID" ]; then
        print_success "Frontend started (PID: $FLUTTER_PID)"
        echo "           URL: http://localhost:8080"
        echo "           Logs: tail -f $FRONTEND_LOG"
    else
        print_error "Failed to start frontend. Check logs: tail -f $FRONTEND_LOG"
        exit 1
    fi
}

# Start backend
start_backend() {
    print_header "Start Backend"

    BACKEND_PID=$(get_backend_pid)
    if [ -n "$BACKEND_PID" ]; then
        print_warning "Backend is already running (PID: $BACKEND_PID)"
        return
    fi

    print_info "Starting FastAPI backend on port 8000..."
    cd $BACKEND_DIR

    # Activate virtual environment
    if [ ! -d ".venv" ]; then
        print_error "Virtual environment not found at $BACKEND_DIR/.venv"
        exit 1
    fi

    # Clear old log
    > $BACKEND_LOG

    # Start backend in background
    nohup .venv/bin/uvicorn main:app --reload --port 8000 > $BACKEND_LOG 2>&1 &

    print_info "Waiting for backend to start..."
    sleep 3

    BACKEND_PID=$(get_backend_pid)
    if [ -n "$BACKEND_PID" ]; then
        print_success "Backend started (PID: $BACKEND_PID)"
        echo "           URL: http://localhost:8000"
        echo "           API Docs: http://localhost:8000/docs"
        echo "           Logs: tail -f $BACKEND_LOG"

        # Wait for health check
        for i in {1..10}; do
            if curl -s http://localhost:8000/healthz > /dev/null 2>&1; then
                print_success "Backend is healthy"
                break
            fi
            sleep 1
        done
    else
        print_error "Failed to start backend. Check logs: tail -f $BACKEND_LOG"
        exit 1
    fi
}

# Restart frontend (full restart, not hot reload)
restart_frontend() {
    stop_frontend
    start_frontend
}

# Restart backend
restart_backend() {
    stop_backend
    start_backend
}

# Restart everything
restart_all() {
    print_header "Restart All Services"
    stop_frontend
    stop_backend
    echo ""
    start_backend
    echo ""
    start_frontend
}

# Start everything
start_all() {
    print_header "Start All Services"
    start_backend
    echo ""
    start_frontend
}

# Stop everything
stop_all() {
    print_header "Stop All Services"
    stop_frontend
    echo ""
    stop_backend
}

# View logs
logs() {
    print_header "Service Logs"

    case "${2:-both}" in
        frontend|fe|f)
            print_info "Frontend logs (Ctrl+C to exit):"
            tail -f $FRONTEND_LOG
            ;;
        backend|be|b)
            print_info "Backend logs (Ctrl+C to exit):"
            tail -f $BACKEND_LOG
            ;;
        both|all)
            print_info "Both logs (Ctrl+C to exit):"
            tail -f $FRONTEND_LOG -f $BACKEND_LOG
            ;;
        *)
            print_error "Unknown log target: $2"
            echo "Usage: ./dev.sh logs [frontend|backend|both]"
            exit 1
            ;;
    esac
}

# Run tests
test_frontend() {
    print_header "Run Frontend Tests"

    cd $FRONTEND_DIR
    print_info "Running Flutter tests..."
    flutter test
}

test_backend() {
    print_header "Run Backend Tests"

    cd $BACKEND_DIR
    print_info "Running pytest..."
    .venv/bin/pytest
}

test_all() {
    test_backend
    echo ""
    test_frontend
}

# Show help
show_help() {
    cat << EOF
Workout Planner - Local Development Script

USAGE:
    ./dev.sh <command>

COMMANDS:
    Status & Monitoring:
        status              Show status of all services
        logs [target]       Tail logs (frontend|backend|both, default: both)

    Quick Reload (Frontend Only):
        hot-reload          Hot reload Flutter (fast, preserves state)
        hot-restart         Hot restart Flutter (slower, resets state)

    Start Services:
        start-all           Start both frontend and backend
        start-frontend      Start Flutter web app
        start-backend       Start FastAPI backend

    Stop Services:
        stop-all            Stop both frontend and backend
        stop-frontend       Stop Flutter web app
        stop-backend        Stop FastAPI backend

    Restart Services:
        restart-all         Restart both services (full restart)
        restart-frontend    Restart Flutter web app (full restart)
        restart-backend     Restart FastAPI backend

    Testing:
        test-all            Run all tests
        test-frontend       Run Flutter tests
        test-backend        Run backend tests

    Help:
        help                Show this help message

EXAMPLES:
    # Check if services are running
    ./dev.sh status

    # Quick reload after code changes (recommended)
    ./dev.sh hot-reload

    # Full restart if hot reload doesn't work
    ./dev.sh hot-restart

    # Restart everything
    ./dev.sh restart-all

    # View logs
    ./dev.sh logs frontend
    ./dev.sh logs backend
    ./dev.sh logs both

PORTS:
    Frontend:  http://localhost:8080
    Backend:   http://localhost:8000
    API Docs:  http://localhost:8000/docs

LOGS:
    Frontend:  $FRONTEND_LOG
    Backend:   $BACKEND_LOG

EOF
}

# Main command router
case "${1:-help}" in
    status|st)
        check_status
        ;;
    hot-reload|reload|hr|r)
        hot_reload
        ;;
    hot-restart|restart-hot|hR)
        hot_restart
        ;;
    start-all|start|up)
        start_all
        ;;
    start-frontend|start-fe|sf)
        start_frontend
        ;;
    start-backend|start-be|sb)
        start_backend
        ;;
    stop-all|stop|down)
        stop_all
        ;;
    stop-frontend|stop-fe)
        stop_frontend
        ;;
    stop-backend|stop-be)
        stop_backend
        ;;
    restart-all|restart)
        restart_all
        ;;
    restart-frontend|restart-fe)
        restart_frontend
        ;;
    restart-backend|restart-be)
        restart_backend
        ;;
    logs|log|l)
        logs "$@"
        ;;
    test-all|test)
        test_all
        ;;
    test-frontend|test-fe)
        test_frontend
        ;;
    test-backend|test-be)
        test_backend
        ;;
    help|--help|-h|h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

case "${1:-help}" in
  docker)
    echo "=== Starting all services (Docker) ==="
    echo "Backend  → http://localhost:8000/api/v1/"
    echo "Frontend → http://localhost:3000"
    docker compose -f "$ROOT/docker-compose.yml" up --build
    ;;

  docker-detached)
    echo "=== Starting all services in background ==="
    docker compose -f "$ROOT/docker-compose.yml" up --build -d
    echo "Frontend → http://localhost:3000"
    echo "Backend  → http://localhost:8000/api/v1/"
    echo "Use 'docker compose logs -f' to follow logs."
    ;;

  backend)
    echo "=== Running backend locally (Django + SQLite) ==="
    cd "$ROOT/backend"
    if [ ! -d venv ]; then
      python3 -m venv venv
    fi
    source venv/bin/activate
    pip install -q -r requirements.txt
    [ -f .env ] || cp .env.example .env
    python manage.py migrate
    echo "Backend → http://localhost:8000"
    python manage.py runserver 0.0.0.0:8000
    ;;

  frontend)
    echo "=== Running frontend locally (Flutter web) ==="
    cd "$ROOT/frontend"
    flutter pub get
    echo "Frontend → http://localhost:3000 (or the port Flutter assigns)"
    flutter run -d chrome
    ;;

  dev)
    echo "=== Running backend then frontend (local dev) ==="
    echo "Start backend in one terminal:   ./run.sh backend"
    echo "Start frontend in another:       ./run.sh frontend"
    ;;

  stop)
    echo "=== Stopping Docker containers ==="
    docker compose -f "$ROOT/docker-compose.yml" down
    ;;

  help|*)
    echo "Usage: ./run.sh <command>"
    echo ""
    echo "Commands:"
    echo "  docker            Start all services via Docker Compose (foreground)"
    echo "  docker-detached   Start all services via Docker Compose (background)"
    echo "  backend           Run backend locally (Django runserver)"
    echo "  frontend          Run frontend locally (Flutter web on Chrome)"
    echo "  dev               Print instructions for local development"
    echo "  stop              Stop all Docker containers"
    echo ""
    echo "Docker mode:"
    echo "  Backend  → http://localhost:8000/api/v1/"
    echo "  Frontend → http://localhost:3000"
    ;;
esac

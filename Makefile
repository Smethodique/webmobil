.PHONY: help build up down logs logs-backend logs-frontend logs-db logs-redis logs-celery logs-beat logs-follow ps clean rebuild restart stop

# Color output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

help:
	@echo "$(BLUE)========================================$(NC)"
	@echo "$(BLUE)   Docker Compose Commands$(NC)"
	@echo "$(BLUE)========================================$(NC)"
	@echo "$(GREEN)Build & Start:$(NC)"
	@echo "  make build              - Build Docker images"
	@echo "  make up                 - Start containers (with build logs)"
	@echo "  make up-no-build        - Start containers without rebuild"
	@echo ""
	@echo "$(GREEN)Stop & Cleanup:$(NC)"
	@echo "  make down               - Stop containers (with logs)"
	@echo "  make stop               - Stop without removing volumes"
	@echo "  make clean              - Remove containers and volumes"
	@echo "  make restart            - Restart all containers"
	@echo ""
	@echo "$(GREEN)View Logs:$(NC)"
	@echo "  make logs               - View all container logs"
	@echo "  make logs-backend       - View backend logs"
	@echo "  make logs-frontend      - View frontend logs"
	@echo "  make logs-db            - View database logs"
	@echo "  make logs-redis         - View Redis logs"
	@echo "  make logs-celery        - View Celery worker logs"
	@echo "  make logs-beat          - View Celery beat logs"
	@echo "  make logs-follow        - Follow all logs (live)"
	@echo ""
	@echo "$(GREEN)Info:$(NC)"
	@echo "  make ps                 - Show running containers"
	@echo "  make rebuild            - Clean rebuild everything"
	@echo "$(BLUE)========================================$(NC)"

build:
	@echo "$(YELLOW)[BUILD] Building Docker images...$(NC)"
	@docker compose build --no-cache 2>&1 | tee build-logs.txt
	@echo "$(GREEN)✓ Build complete! Logs saved to build-logs.txt$(NC)"

up:
	@echo "$(YELLOW)[UP] Starting containers with build and showing logs...$(NC)"
	@docker compose up --build 2>&1 | tee up-logs.txt

up-no-build:
	@echo "$(YELLOW)[UP] Starting containers without rebuild...$(NC)"
	@docker compose up 2>&1 | tee up-logs.txt

down:
	@echo "$(YELLOW)[DOWN] Stopping containers...$(NC)"
	@docker compose down 2>&1 | tee down-logs.txt
	@echo "$(GREEN)✓ Containers stopped! Logs saved to down-logs.txt$(NC)"

stop:
	@echo "$(YELLOW)[STOP] Stopping containers (keeping volumes)...$(NC)"
	@docker compose stop 2>&1 | tee stop-logs.txt
	@echo "$(GREEN)✓ Containers stopped! Logs saved to stop-logs.txt$(NC)"

logs:
	@echo "$(YELLOW)[LOGS] Showing all container logs (last 100 lines)...$(NC)"
	@docker compose logs --tail=100

logs-backend:
	@echo "$(YELLOW)[LOGS] Backend logs (last 100 lines)...$(NC)"
	@docker compose logs --tail=100 backend

logs-frontend:
	@echo "$(YELLOW)[LOGS] Frontend logs (last 100 lines)...$(NC)"
	@docker compose logs --tail=100 frontend

logs-db:
	@echo "$(YELLOW)[LOGS] Database logs (last 100 lines)...$(NC)"
	@docker compose logs --tail=100 db

logs-redis:
	@echo "$(YELLOW)[LOGS] Redis logs (last 100 lines)...$(NC)"
	@docker compose logs --tail=100 redis

logs-celery:
	@echo "$(YELLOW)[LOGS] Celery worker logs (last 100 lines)...$(NC)"
	@docker compose logs --tail=100 celery_worker

logs-beat:
	@echo "$(YELLOW)[LOGS] Celery beat logs (last 100 lines)...$(NC)"
	@docker compose logs --tail=100 celery_beat

logs-follow:
	@echo "$(YELLOW)[LOGS] Following all logs in real-time (Ctrl+C to stop)...$(NC)"
	@docker compose logs -f

ps:
	@echo "$(YELLOW)[PS] Running containers:$(NC)"
	@docker compose ps

clean:
	@echo "$(RED)[CLEAN] Removing all containers and volumes...$(NC)"
	@docker compose down -v 2>&1 | tee clean-logs.txt
	@echo "$(GREEN)✓ Cleanup complete! Logs saved to clean-logs.txt$(NC)"

restart: down up-no-build

rebuild: clean build up

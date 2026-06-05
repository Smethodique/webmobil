#!/bin/bash

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display menu
show_menu() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}   Docker Compose Logs & Management${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}1${NC}) Build and show logs (docker-compose up --build)"
    echo -e "${GREEN}2${NC}) Start without rebuild (docker-compose up)"
    echo -e "${GREEN}3${NC}) Stop containers (docker-compose down)"
    echo -e "${GREEN}4${NC}) View all logs"
    echo -e "${GREEN}5${NC}) View backend logs"
    echo -e "${GREEN}6${NC}) View frontend logs"
    echo -e "${GREEN}7${NC}) View database logs"
    echo -e "${GREEN}8${NC}) View Redis logs"
    echo -e "${GREEN}9${NC}) View Celery worker logs"
    echo -e "${GREEN}10${NC}) View Celery beat logs"
    echo -e "${GREEN}11${NC}) Follow all logs (live)"
    echo -e "${GREEN}12${NC}) Clean up everything (down + remove volumes)"
    echo -e "${GREEN}0${NC}) Exit"
    echo -e "${BLUE}========================================${NC}"
    echo -n "Choose an option: "
}

# Function to show build logs
build_with_logs() {
    echo -e "\n${YELLOW}[INFO] Building Docker images...${NC}"
    docker-compose build --no-cache 2>&1 | tee build-logs.txt
    echo -e "\n${YELLOW}[INFO] Build logs saved to build-logs.txt${NC}"
}

# Function to start with build and show logs
start_build_logs() {
    echo -e "\n${YELLOW}[INFO] Starting containers with build and showing logs...${NC}"
    docker-compose up --build 2>&1 | tee up-logs.txt
}

# Function to start without rebuild
start_logs() {
    echo -e "\n${YELLOW}[INFO] Starting containers and showing logs...${NC}"
    docker-compose up 2>&1 | tee up-logs.txt
}

# Function to stop and show logs
stop_logs() {
    echo -e "\n${YELLOW}[INFO] Stopping containers and showing logs...${NC}"
    docker-compose down -v 2>&1 | tee down-logs.txt
    echo -e "\n${GREEN}✓ Containers stopped${NC}"
    echo -e "${YELLOW}[INFO] Down logs saved to down-logs.txt${NC}"
}

# Function to view all logs
view_all_logs() {
    echo -e "\n${YELLOW}[INFO] Viewing all container logs...${NC}"
    docker-compose logs --tail=100
}

# Function to view specific service logs
view_service_logs() {
    local service=$1
    echo -e "\n${YELLOW}[INFO] Viewing ${service} logs (last 100 lines)...${NC}"
    docker-compose logs --tail=100 $service
}

# Function to follow logs in real-time
follow_logs() {
    echo -e "\n${YELLOW}[INFO] Following all logs in real-time (Ctrl+C to stop)...${NC}"
    docker-compose logs -f
}

# Function to clean everything
clean_all() {
    echo -e "\n${RED}[WARNING] This will remove all containers and volumes!${NC}"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        echo -e "\n${YELLOW}[INFO] Cleaning up Docker resources...${NC}"
        docker-compose down -v
        echo -e "\n${GREEN}✓ Cleanup complete${NC}"
    else
        echo -e "${YELLOW}[INFO] Cleanup cancelled${NC}"
    fi
}

# Main loop
while true; do
    show_menu
    read choice

    case $choice in
        1)
            build_with_logs
            ;;
        2)
            start_logs
            ;;
        3)
            stop_logs
            ;;
        4)
            view_all_logs
            ;;
        5)
            view_service_logs backend
            ;;
        6)
            view_service_logs frontend
            ;;
        7)
            view_service_logs db
            ;;
        8)
            view_service_logs redis
            ;;
        9)
            view_service_logs celery_worker
            ;;
        10)
            view_service_logs celery_beat
            ;;
        11)
            follow_logs
            ;;
        12)
            clean_all
            ;;
        0)
            echo -e "\n${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
done

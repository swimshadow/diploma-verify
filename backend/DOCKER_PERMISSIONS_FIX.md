# Diploma-Verify docker-compose Quick Start Guide
# =============================================

## Problem: Docker Permission Denied
# If you get "permission denied while trying to connect to the docker API",
# use one of these solutions:

### SOLUTION 1: Use the wrapper script (Recommended)
cd backend
./docker-compose-wrapper.sh up -d

### SOLUTION 2: Use sg (security group) command
cd backend
sg docker -c "docker-compose up -d"

### SOLUTION 3: Use sudo (Not recommended for general use)
cd backend
sudo docker-compose up -d

### SOLUTION 4: Activate docker group for current session
# First, add user to docker group (one-time):
sudo usermod -aG docker $USER

# Then log out and log back in, or activate group in current session:
newgrp docker

# Then use docker-compose normally:
docker-compose up -d

## Setup on New System:
1. Install Docker daemon:
   sudo apt-get install docker.io

2. Add user to docker group:
   sudo usermod -aG docker $USER

3. Activate group:
   newgrp docker

4. Test:
   docker ps

## Common Commands:

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs of a service
docker-compose logs <service-name>

# Stop all services
docker-compose down

# Rebuild a service
docker-compose build <service-name>

# Restart a service
docker-compose restart <service-name>

## Useful Commands:

# View all running containers
docker ps

# Execute command in container
docker-compose exec <service-name> <command>

# Connect to PostgreSQL
docker-compose exec postgres psql -U hack -d diplomadb

# View docker socket permissions
ls -la /var/run/docker.sock

# Check if current user is in docker group
groups $USER

## Notes:
- The wrapper script automatically detects your docker group status
- SMTP warnings are normal in development mode
- All services should show "Up" and "healthy" status
- API docs available at: http://localhost:8000/docs

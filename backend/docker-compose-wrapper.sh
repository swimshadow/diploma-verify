#!/bin/bash

# Docker Compose Wrapper
# Automatically uses docker group when available

# Check if user is in docker group
if groups "$USER" | grep -q "\bdocker\b"; then
    # User is in docker group, run normally
    docker-compose "$@"
else
    # User is not in docker group, use sg
    sg docker -c "docker-compose $@"
fi

#!/bin/sh

# Environment variables used in CI build
export APP_VERSION="0.0.1" 
export APP_NAME="tinyurl"
export COMPOSE_FILE="ci/docker-compose.yml"
export PROJECT_DIR=$(pwd)

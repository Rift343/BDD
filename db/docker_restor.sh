#!/bin/bash

# Stop and remove all containers and volumes
sudo docker compose down -v

# Remove the volume
sudo docker volume rm db_db_data

# Rebuild and start the containers
sudo docker compose build

sudo docker compose up -d

sudo docker compose start

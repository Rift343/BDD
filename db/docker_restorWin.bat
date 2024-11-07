docker compose down -v
docker volume rm db_db_data
docker compose build
docker compose up -d
docker compose start
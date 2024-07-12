@echo off

docker compose --profile no-worker --env-file ./local-development/compose/.env.local up -d

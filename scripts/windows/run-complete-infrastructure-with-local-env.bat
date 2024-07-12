@echo off

docker compose --profile worker --env-file ./local-development/compose/.env.local up -d

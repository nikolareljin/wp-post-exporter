#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

docker compose -f test/docker-compose.yml down -v

echo "Environment torn down (containers and volumes removed)."


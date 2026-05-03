#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/opt/PaiFlow}"
COMPOSE_DIR="${PROJECT_ROOT}/docker/PaiFlow"
COMPOSE_FILE="${COMPOSE_DIR}/docker-compose.prod.yaml"
DEFAULT_SERVICES=("console-frontend" "console-hub" "core-workflow-java" "core-aitools")

if [[ ! -f "${COMPOSE_DIR}/.env" ]]; then
  echo "missing ${COMPOSE_DIR}/.env" >&2
  exit 1
fi

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "missing ${COMPOSE_FILE}" >&2
  exit 1
fi

if [[ -z "${GHCR_USERNAME:-}" || -z "${GHCR_TOKEN:-}" ]]; then
  echo "missing GHCR credentials" >&2
  exit 1
fi

if [[ -z "${IMAGE_PREFIX:-}" || -z "${IMAGE_TAG:-}" ]]; then
  echo "missing IMAGE_PREFIX or IMAGE_TAG" >&2
  exit 1
fi

services=("$@")
if [[ ${#services[@]} -eq 0 ]]; then
  services=("${DEFAULT_SERVICES[@]}")
elif [[ ${#services[@]} -eq 1 && "${services[0]}" == "all" ]]; then
  services=("${DEFAULT_SERVICES[@]}")
elif [[ ${#services[@]} -eq 1 && "${services[0]}" == *","* ]]; then
  IFS=',' read -r -a services <<< "${services[0]}"
fi

echo "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USERNAME}" --password-stdin

cd "${COMPOSE_DIR}"
export IMAGE_PREFIX
export IMAGE_TAG

docker compose -f "${COMPOSE_FILE}" pull "${services[@]}"
docker compose -f "${COMPOSE_FILE}" up -d "${services[@]}"
docker compose -f "${COMPOSE_FILE}" ps

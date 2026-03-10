#!/usr/bin/env bash
set -euo pipefail

RUN_AS_UID="${RUN_AS_UID:-1000}"
RUN_AS_GID="${RUN_AS_GID:-1000}"
SERVICE_CMD="${SERVICE_CMD:-}"

if [[ -z "${SERVICE_CMD}" ]]; then
  echo "SERVICE_CMD is not set."
  exit 1
fi

read -r -a cmd_parts <<< "${SERVICE_CMD}"
if [[ "${#cmd_parts[@]}" -eq 0 ]]; then
  echo "SERVICE_CMD is empty after parsing."
  exit 1
fi

if ! getent group "${RUN_AS_GID}" >/dev/null 2>&1; then
  groupadd -g "${RUN_AS_GID}" dsrun
fi

if ! id -u "${RUN_AS_UID}" >/dev/null 2>&1; then
  useradd -m -u "${RUN_AS_UID}" -g "${RUN_AS_GID}" dsrun
fi

mkdir -p /opt/darkspace/bin /opt/darkspace/config /opt/darkspace/logs
chown -R "${RUN_AS_UID}:${RUN_AS_GID}" /opt/darkspace

service_bin="${cmd_parts[0]}"
service_bin="${service_bin#./}"
service_bin_path="/opt/darkspace/bin/${service_bin}"
if [[ ! -f "${service_bin_path}" ]]; then
  echo "Service binary not found: ${service_bin_path}"
  exit 1
fi

if [[ "${#cmd_parts[@]}" -gt 1 ]]; then
  service_cfg="${cmd_parts[1]}"
  if [[ "${service_cfg}" == ../config/* ]]; then
    cfg_name="${service_cfg#../config/}"
    service_cfg_path="/opt/darkspace/config/${cfg_name}"
    if [[ ! -f "${service_cfg_path}" ]]; then
      echo "Service config not found: ${service_cfg_path}"
      exit 1
    fi
  fi
fi

echo "Starting service: ${SERVICE_CMD}"
exec gosu "${RUN_AS_UID}:${RUN_AS_GID}" bash -lc "cd /opt/darkspace/bin && ${SERVICE_CMD}"

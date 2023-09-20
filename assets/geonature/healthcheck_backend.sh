#!/bin/bash
# docker healthcheck GN backend

url_test=http://localhost:8000${GEONATURE_BACKEND_PREFIX}/gn_commons/config
if [ ! -f /tmp/container_healthy ]; then
    curl --noproxy localhost -f "${url_test}" || exit 1
    touch /tmp/container_healthy
fi

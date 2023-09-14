#!/bin/sh
# docker healthcheck GN frontend
url_test=http://localhost:80${NGINX_LOCATION}/
if [ ! -f /tmp/container_healthy ]; then
    curl --noproxy localhost -f "${url_test}" || exit 1
    touch /tmp/container_healthy
fi
#!/bin/bash
if [ ! -f /tmp/container_healthy ]; then
    export PGPASSWORD=${POSTGRES_PASSWORD}
    # test if pg_trgm is installed
    psql -d ${POSTGRES_DB} -U ${POSTGRES_USER} -c "SELECT similarity('a', 'b')" || exit 1;
    touch /tmp/container_healthy
fi
exit 0


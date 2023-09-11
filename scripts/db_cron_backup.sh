#!/bin/bash

BASEDIR=$(dirname "$0")/..
cd "$BASEDIR"
docker compose exec postgres /bin/sh /scripts/backup.sh

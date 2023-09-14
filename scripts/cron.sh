#!/bin/bash

projet_dir=$(dirname "$0")/..
cd "$projet_dir"

# raffraichissement des vues de l'atlas
docker compose exec postgres /bin/sh /scripts/refresh_atlas.sh

# backup de la bdd
docker compose exec postgres /bin/sh /scripts/backup.sh

# backup des fichier des services (sauf backup de la base)
rm -f data/services/services.tar.gz
tar cvfz --exclude 'geonature_backup*' ./data/services/services.tar.gz data/services/


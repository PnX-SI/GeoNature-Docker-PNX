#!/bin/bash
env_file=$1

[[ -z "${env_file}" ]] && echo "Veuillez entrer un fichier de configuration (.env)" && exit 1
[[ ! -f "${env_file}" ]] && echo "Le fichier de configuration ${env_file} n'a pas été trouvé" && exit 1

source ${env_file}

touch ${GEONATURE_VOLUME_CONFIG_DIRECTORY}/geonature_config.toml
touch ${TAXHUB_VOLUME_CONFIG_DIRECTORY}/config.py
touch ${USERSHUB_VOLUME_CONFIG_DIRECTORY}/config.py
touch ${ATLAS_VOLUME_CONFIG_DIRECTORY}/config.py

mkdir -p ${PGADMIN_VOLUME_DATA_DIRECTORY}
sudo chown -R 5050:5050 ${PGADMIN_VOLUME_DATA_DIRECTORY}

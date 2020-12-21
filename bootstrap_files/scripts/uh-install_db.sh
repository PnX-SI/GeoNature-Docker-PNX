#!/bin/bash

. /usr/local/utils.lib.sh

verbose=1
mkdir -p ${UH_HOME}/{tmp/usershub,var/log/installdb}

#include user config = settings.ini
. ${UH_HOME}/config/settings.ini

LOG_DIR=${UH_HOME}/var/log

export PGPASSWORD=$user_pg_pass

cd ${UH_HOME}

_verbose_echo "${green}Usershub - ${nocolor}Création du schéma utilisateur..."
psql -h $db_host -U $user_pg -d $db_name -f data/usershub.sql &>> $LOG_DIR/installdb/install_db.log
if $insert_minimal_data
    then
    ## Insert minimal data
    _verbose_echo "${green}Usershub - ${nocolor}Insertion des données minimum..."
    psql -h $db_host -U $user_pg -d $db_name -f data/usershub-data.sql &>> $LOG_DIR/installdb/install_db.log
fi
if $insert_sample_data
    then
    ## Insert sample data
    _verbose_echo "${green}Usershub - ${nocolor}Insertion des données exemples..."
    psql -h $db_host -U $user_pg -d $db_name -f data/usershub-dataset.sql &>> $LOG_DIR/installdb/install_db.log
fi

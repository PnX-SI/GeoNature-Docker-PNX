#!/bin/bash

# lancement des application liées à Géonature
#
# Si la BDD n'existe pas -> installation de la BDD (correspondante à la version de geonature)
#
# Si les applications ou les modules  de sont pas installée le script procède à l'installation des applications
#
# Procédure de Mise à jour en cours, pour les applications et les modules
# (si la version installée difère de la version spécifiée )

# arret en cas d'erreur
set -e

# affichage des commandes si DEBUG
if $DEBUG; then 
    set -x
fi

# Initialisation

mnt_bootstrap_dir=/mnt_bootstrap_files
geonature_user=geonatureadmin
export script_home_dir=/geonature
export bootstrap_dir=/bootstrap_files
export verbose=1

. /usr/local/utils.lib.sh
. /usr/local/utils.lib.install.sh

_verbose_echo "${green}launch_app - ${nocolor}Droits sur le répertoire ${script_home_dir}"
sudo chown -R ${geonature_user}. ${script_home_dir}

_verbose_echo "${green}launch_app - ${nocolor}Attente de la base de données..."
wait_for_restart db:5432

# On concatene les applications, modules GN et modules MONITORING en une seule variable ALL_DEPOTS

export ALL_DEPOTS="${APPLICATIONS} ${MODULES_GEONATURE} ${MODULES_MONITORING}"

# (DEV) Possibilité de refaire tout si la variable RESET_ALL est à true

if $RESET_ALL; then

    _verbose_echo "${green}launch_app - ${nocolor}RESET"

    # effacement des :

    # - config supervisor
    rm -f ${script_home_dir}/sysfiles/supervisor/*.conf

    # version installée
    rm -f /$script_home_dir/sysfiles/installed/*

    # depots git
    for name_version in $(echo ${ALL_DEPOTS}); do
        name=${name_version%-*}
        sudo rm -Rf ${script_home_dir}/$name
    done
fi


## Start supervisor

_verbose_echo "${green}launch_app - ${nocolor}Copie de la conf de supervisor (si existe)"

mkdir -p ${script_home_dir}/sysfiles/supervisor
sudo cp ${script_home_dir}/sysfiles/supervisor/*.conf /etc/supervisor/conf.d/ || true

sudo /usr/bin/supervisord&
sleep 1
sudo supervisorctl stop all

_verbose_echo "${green}launch_app - ${nocolor}Copie des scripts du volume vers ${bootstrap_dir} et droits"
sudo cp -R ${mnt_bootstrap_dir}/* ${bootstrap_dir}/
sudo chmod -R a+rx ${bootstrap_dir}


# BDD

# Installation de la base de données si 
# - le fichier $script_home_dir/sysfiles/installed/${name} n'existe pas
# - la base de données n'existe pas 
#      (sauf si la variable 'drop_apps_db' est à true dans geonature.settings.ini)

version_db=$(get_version_installed db)
if [ -z "${version_db}" ] ; then
    _verbose_echo "${green}launch_app - ${nocolor}Installation de la base de donnée GeoNature $(get_version geonature)"
    install_db
fi


# Applications et module (Installation / Mise à jour)

# Pour relancer le build du frontend après l'installation de modules en série
# Le fait on à chaque redemarrage ?

# export build_geonature_frontend=''

for name_version in $(echo ${ALL_DEPOTS}); do
    install_or_update $name_version
done 

# if [ ! -z "$build_geonature_frontend" ]; then
# on le fait à chaque fois ça coute pas plus cher
source $script_home_dir/geonature/backend/venv/bin/activate
geonature_up_config_and_build
# fi


# supervisor

# save supervisor files & stop
sudo cp /etc/supervisor/conf.d/* ${script_home_dir}/sysfiles/supervisor/
sudo supervisorctl reread
sudo supervisorctl reload
sudo supervisorctl stop all
sudo supervisorctl shutdown



if [[ ! -z $1 ]]; then

    # lancement d'un bash (docker exec)

    _verbose_echo "${green}launch_app - ${nocolor}Lancement d'un bash"
    /bin/bash -c $1
else

    # lancement de de supervisor en tâche principale
    # ?? à optimiser

    _verbose_echo "${green}launch_app - ${nocolor}Relacement de supervisor en tâche principale"
    sudo /usr/bin/supervisord
fi

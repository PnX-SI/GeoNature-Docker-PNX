#!/bin/bash

set -e


script_home_dir=/geonature
mnt_bootstrap_dir=/mnt_bootstrap_files
bootstrap_dir=/bootstrap_files
geonature_user=geonatureadmin
cd $script_home_dir

verbose=1

. /usr/local/utils.lib.sh


_verbose_echo "${green}launch_app - ${nocolor}Droits sur le répertoire ${script_home_dir}"
sudo chown -R ${geonature_user}. ${script_home_dir}

_verbose_echo "${green}launch_app - ${nocolor}Attente de la base de données..."
wait_for_restart db:5432

## Start supervisor
_verbose_echo "${green}launch_app - ${nocolor}Copie de la conf de supervisor (si existe)"
mkdir -p ${script_home_dir}/sysfiles/supervisor
sudo cp ${script_home_dir}/sysfiles/supervisor/*.conf /etc/supervisor/conf.d/

_verbose_echo "${green}launch_app - ${nocolor}Copie des scripts du volume vers ${bootstrap_dir} et droits"
sudo cp -R ${mnt_bootstrap_dir}/* ${bootstrap_dir}/
sudo chmod -R a+rx ${bootstrap_dir}

# Recupération du depot gn{version} et assignation des versions
_verbose_echo "${green}launch_app - ${nocolor}Récupération dépot Geonature ${GEONATURE_VERSION}"
export script_home_dir=/geonature
export GN_HOME=${script_home_dir}/geonature
get_depot_git https://github.com/PnX-SI/GeoNature.git ${GEONATURE_VERSION} ${GN_HOME}


# Versions des autres applications depuis ${GN_HOME}/config/settings.ini.sample
cat ${GN_HOME}/config/settings.ini.sample | grep _release  > ${script_home_dir}/version.ini
. ${script_home_dir}/version.ini

geonature_release=${GEONATURE_VERSION}
USERSHUB_VERSION=${usershub_release}
TAXHUB_VERSION=${taxhub_release}


# Recuperation des depots autres{version} 
_verbose_echo "${green}launch_app - ${nocolor}Récupération dépot UsersHub ${USERSHUB_VERSION}"
export UH_HOME=${script_home_dir}/usershub
get_depot_git https://github.com/PnX-SI/Usershub.git ${USERSHUB_VERSION} ${UH_HOME}

_verbose_echo "${green}launch_app - ${nocolor}Récupération dépot TaxHub ${TAXHUB_VERSION}"
export TH_HOME=${script_home_dir}/taxhub
get_depot_git https://github.com/PnX-SI/Taxhub.git ${TAXHUB_VERSION} ${TH_HOME}


# settings.ini et autres config..
cp ${bootstrap_dir}/gn.settings.ini ${GN_HOME}/config/settings.ini
cat ${script_home_dir}/version.ini  >> ${GN_HOME}/config/settings.ini

cp ${bootstrap_dir}/uh.settings.ini ${UH_HOME}/config/settings.ini
cp ${bootstrap_dir}/th.settings.ini ${TH_HOME}/settings.ini

# Installation de la bdd (si besoin)

rm /$script_home_dir/sysfiles/*_installed

version_geonature_depot=$GEONATURE_VERSION
version_geonature_installee=$(get_version_installee /$script_home_dir/sysfiles geonature)
version_usershub_depot=$USERSHUB_VERSION
version_usershub_installee=$(get_version_installee /$script_home_dir/sysfiles usershub)
version_taxhub_depot=$TAXHUB_VERSION
version_taxhub_installee=$(get_version_installee /$script_home_dir/sysfiles taxhub)

if [ -z "$version_geonature_installed" ]; then
    . ${bootstrap_dir}/scripts/install_db.sh
fi


if [ "$version_geonature_installle" != "$version_geonature_depot" ] \
    || [ "$version_usershub_installle" != "$version_usershub_depot" ] \
    || [ "$version_taxhub_installle" != "$version_taxhub_depot" ] \
    ; then

    sudo /usr/bin/supervisord &
    for app in 'geonature' 'usershub' 'taxhub'; do


        version_depot=version_${app}_depot
        version_depot=${!version_depot}

        version_installee=version_${app}_installee
        version_installee=${!version_installee}
        
        /bin/bash ${bootstrap_dir}/scripts/install_app.sh ${app} ${version_depot} ${version_installee}
        

    done

    sudo supervisorctl stop all
    sleep 5
    sudo supervisorctl shutdown
    sleep 5

fi

if [[ ! -z $1 ]]; then
    _verbose_echo "${green}launch_app - ${nocolor}Lancement d'un bash"
    /bin/bash -c $1
else
    _verbose_echo "${green}launch_app - ${nocolor}Relacement de supervisor en tâche principale"
    sudo /usr/bin/supervisord
fi

exit 1
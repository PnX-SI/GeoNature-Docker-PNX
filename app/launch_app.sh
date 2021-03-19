#!/bin/bash
set -e

if $DEBUG; then 
set -x
fi


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

## Start supervisor
_verbose_echo "${green}launch_app - ${nocolor}Copie de la conf de supervisor (si existe)"
mkdir -p ${script_home_dir}/sysfiles/supervisor
# sudo cp ${script_home_dir}/sysfiles/supervisor/*.conf /etc/supervisor/conf.d/ || true

#
_verbose_echo "${green}launch_app - ${nocolor}Copie des scripts du volume vers ${bootstrap_dir} et droits"
sudo cp -R ${mnt_bootstrap_dir}/* ${bootstrap_dir}/
sudo chmod -R a+rx ${bootstrap_dir}


# reset !!!!!
if $RESET_ALL; then
    rm -f /$script_home_dir/sysfiles/*_installed
    for name_version in $(echo ${APPLICATIONS} ${MODULES_GEONATURE}); do
        name=${name_version%-*}
        rm -Rf ${script_home_dir}/$name
    done
fi

version_db=$(get_version_installed db)
# # Base de données
if [ -z "${version_db}" ] ; then
    _verbose_echo "${green}launch_app - ${nocolor}Installation base GeoNature $(get_version geonature)"
    . ${bootstrap_dir}/scripts/install_db.sh
fi

export rebuid_for_module=''

# # Applications / modules
for name_version in $(echo ${APPLICATIONS} ${MODULES_GEONATURE} ${MODULES_MONITORING}); do
    install_or_update $name_version
done 


# pour ne pas refaire un build à chaque module
if [ ! -z "$rebuild_for_modules" ]; then
    source $script_home_dir/geonature/backend/venv/bin/activate
    geonature frontend_build
fi
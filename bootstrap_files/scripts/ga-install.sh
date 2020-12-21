#!/bin/bash

script_home_dir=/geonature
bootstrap_dir=/bootstrap_files
verbose=1

GA_VERSION="1.4.1"
export GA_HOME=${script_home_dir}/atlas

. /usr/local/utils.lib.sh

cd $script_home_dir

_verbose_echo "${orange}Début d'installation de Géonature Atlas!${nocolor}"

## Geonature Atlas
wget -q "https://github.com/PnX-SI/GeoNature-atlas/archive/${GA_VERSION}.zip"
unzip -q "${GA_VERSION}.zip"
mv GeoNature-atlas-${GA_VERSION} ${GA_HOME}/
cp ${bootstrap_dir}/ga.settings.ini ${GA_HOME}/atlas/configuration/settings.ini



## Install Geonature Atlas
cd ${GA_HOME}/
mkdir -p log var/log
touch test.log




cp ${bootstrap_dir}/scripts/ga-install_db.sh .
/bin/bash ./ga-install_db.sh

./install_app.sh

sudo cp /etc/supervisor/conf.d/*.conf ${script_home_dir}/sysfiles/supervisor/
touch ${script_home_dir}/sysfiles/atlas_installed

_verbose_echo "${orange}Fin d'installation de Géonature Atlas!${nocolor}"

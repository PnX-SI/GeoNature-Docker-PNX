#!/bin/bash

script_home_dir=/geonature
bootstrap_dir=/bootstrap_files
verbose=1

GN_VERSION="2.5.5"
export GN_HOME=${script_home_dir}/geonature

. /usr/local/utils.lib.sh

cd $script_home_dir

_verbose_echo "${orange}Début d'installation de Geonature!${nocolor}"

## GeoNature
wget -q "https://github.com/PnX-SI/GeoNature/archive/${GN_VERSION}.zip"
unzip -q "${GN_VERSION}.zip"
mv GeoNature-${GN_VERSION} ${GN_HOME}/
cp ${bootstrap_dir}/gn.settings.ini ${GN_HOME}/config/settings.ini



## Install Geonature
cd ${GN_HOME}
mkdir -p log var/log tmp
touch test.log
touch var/log/gn_errors.log

cd install
cp ${bootstrap_dir}/scripts/raster.zip .
cp ${bootstrap_dir}/scripts/gn-install_db.sh .
/bin/bash ./gn-install_db.sh

./install_app.sh

sudo cp /etc/supervisor/conf.d/*.conf ${script_home_dir}/sysfiles/supervisor/
touch ${script_home_dir}/sysfiles/geonature_installed

_verbose_echo "${orange}Fin d'installation de Geonature!${nocolor}"
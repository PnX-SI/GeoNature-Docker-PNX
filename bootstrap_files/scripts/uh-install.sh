#!/bin/bash

script_home_dir=/geonature
bootstrap_dir=/bootstrap_files
verbose=1

UH_VERSION="2.1.3"
export UH_HOME=${script_home_dir}/usershub

. /usr/local/utils.lib.sh

cd $script_home_dir

_verbose_echo "${orange}Début d'installation de UsersHub!${nocolor}"

## UserHub
wget -q "https://github.com/PnX-SI/UsersHub/archive/${UH_VERSION}.zip"
unzip -q "${UH_VERSION}.zip"
mv UsersHub-${UH_VERSION} ${UH_HOME}/
cp ${bootstrap_dir}/uh.settings.ini ${UH_HOME}/config/settings.ini

. ${UH_HOME}/config/settings.ini

## Install UserHub
cd ${UH_HOME}/
mkdir -p log var/log
touch var/log/test.log




cp ${bootstrap_dir}/scripts/uh-install_db.sh .
/bin/bash ./uh-install_db.sh

./install_app.sh

sudo cp /etc/supervisor/conf.d/*.conf ${script_home_dir}/sysfiles/supervisor/
touch ${script_home_dir}/sysfiles/usershub_installed

_verbose_echo "${orange}Fin d'installation de UsersHub!${nocolor}"

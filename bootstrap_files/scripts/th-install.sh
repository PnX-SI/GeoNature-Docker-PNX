#!/bin/bash

script_home_dir=/geonature
bootstrap_dir=/bootstrap_files
verbose=1

TH_VERSION="1.7.3"
export TH_HOME=${script_home_dir}/taxhub

. /usr/local/utils.lib.sh

cd $script_home_dir

_verbose_echo "${orange}Début d'installation de TaxHub  !${nocolor}"

## TaxHub
wget -q "https://github.com/PnX-SI/TaxHub/archive/${TH_VERSION}.zip"
unzip -q "${TH_VERSION}.zip"
mv TaxHub-${TH_VERSION} ${TH_HOME}/
cp ${bootstrap_dir}/th.settings.ini ${TH_HOME}/settings.ini

. ${TH_HOME}/settings.ini

## Install TaxHub
cd ${TH_HOME}
mkdir -p log var/log
touch var/log/tets.log




cp ${bootstrap_dir}/scripts/th-install_db.sh .
/bin/bash ./th-install_db.sh

./install_app.sh

sudo cp /etc/supervisor/conf.d/*.conf ${script_home_dir}/sysfiles/supervisor/
touch ${script_home_dir}/sysfiles/taxhub_installed

_verbose_echo "${orange}Fin d'installation de TaxHub!${nocolor}"

set -e 

application=$1
version_depot=$2
version_installee=$3

. /usr/local/utils.lib.sh
verbose=1

APP_HOME=$script_home_dir/$application

if [ "$application" = 'geonature' ]; then 
    INSTALL_DIR=install
    APP_DIR=backend
    UPDATE_DB_DIR=data/migrations
    CONFIG_DIR=config
    LOG_DIR=var/log
fi

if [ "$application" = 'usershub' ]; then 
    INSTALL_DIR=.
    APP_DIR=.
    UPDATE_DB_DIR=data
    CONFIG_DIR=config
    LOG_DIR=var/log
fi

if [ "$application" = 'taxhub' ]; then 
    INSTALL_DIR=.
    APP_DIR=.
    UPDATE_DB_DIR=data
    CONFIG_DIR=.
    LOG_DIR=var/log
fi

echo version_installee $version_installee 
echo version_depot $version_depot

if [ "$version_installee" = "$version_depot" ]; then 
    _verbose_echo "${green}launch_app - ${nocolor}Application ${application} ${version_depot} Version inchangée"
    # Attention c'est bon pour les tags mais si on est sur une branche qui évolue alors il faut faire les MAJ???
    # Comment tester cela (numéro de commit??)
    # Est ce qu'on limite l'utilisation du docker aux tags
    exit 0

elif [ -z "$version_installee" ]; then

    # installation 
    _verbose_echo "${green}launch_app - ${nocolor}Installation de l'application ${application} ${version_depot}"

    cd ${APP_HOME}/${INSTALL_DIR}
    ./install_app.sh

    echo $version_depot > /$script_home_dir/sysfiles/${application}_installed
    
    echo /$script_home_dir/sysfiles/${application}_installed
    cat /$script_home_dir/sysfiles/${application}_installed

    _verbose_echo "${green}launch_app - ${nocolor}Fin de l'installation de l'application ${application} ${version_depot}"

else

    # mise à jour bdd
    _verbose_echo "${green}launch_app - ${nocolor}Mise à jour de l'application ${application} ${version_installee} -> ${version_depot}"

    _verbose_echo "Mise à jour BDD $version_installee to $version_depot"

    . ${APP_HOME}/$CONFIG_DIR/settings.ini

    echo migration_db_list_files $version_installee $version_depot $APP_HOME/$UPDATE_DB_DIR
    migration_db_list_files $version_installee $version_depot $APP_HOME/$UPDATE_DB_DIR

    update_db_log=$APP_HOME/$LOG_DIR/migrate_db_${version_installee}to${version_depot}.log
    rm -f $update_db_log

    for file in $(migration_db_list_files $version_installee $version_depot $APP_HOME/$UPDATE_DB_DIR)
    do
        # echo "export PGPASSWORD=${user_pg_pass}; psql -h ${db_host} -d ${db_name} -U ${user_pg} -p ${db_port} -f $file"
        export PGPASSWORD=${user_pg_pass}; psql -h ${db_host} -d ${db_name} -U ${user_pg} -p ${db_port} -f $file >> update_db_log 2>> $update_db_log
    done

    cat $update_db_log

    # mise à jour des applications

    source ${APP_HOME}/${APP_DIR}/venv/bin/activate 
    
    cd ${APP_HOME}/${APP_DIR}
    pip install -r requirements.txt # ?? upgrade ??

    if [ "$applicaiton" = "geonature" ]; then
        cd ../frontend
        npm ci
        geonature update_configuration
    fi

    _verbose_echo "${green}launch_app - ${nocolor}Fin de la mise à jour de l'application ${application} ${version_installee} -> ${version_depot}"
    
    # echo $version_depot > /$script_home_dir/sysfiles/${application}_installed

fi


set -e

if $DEBUG; then 
set -x
fi


application=$1
version_depot=$2
version_installee=$3

. /usr/local/utils.lib.sh
verbose=1

APP_HOME=$script_home_dir/$application

if [ "$application" = 'geonature' ]; then 
    INSTALL_DIR=install
    BACKEND_DIR=backend
    UPDATE_DB_DIR=data/migrations
    CONFIG_DIR=config
    LOG_DIR=var/log
    FRONTEND_DIR=frontend
fi

if [ "$application" = 'usershub' ]; then 
    INSTALL_DIR=.
    BACKEND_DIR=.
    UPDATE_DB_DIR=data
    CONFIG_DIR=config
    LOG_DIR=var/log
    FRONTEND_DIR=app/static
fi

if [ "$application" = 'taxhub' ]; then 
    INSTALL_DIR=.
    BACKEND_DIR=.
    UPDATE_DB_DIR=data
    CONFIG_DIR=.
    LOG_DIR=var/log
    FRONTEND_DIR=static
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

    echo 'set -e' > ./install_app2.sh
    if $DEBUG; then 
        echo 'set -x' >> ./install_app2.sh
    fi

    cat ./install_app.sh >> ./install_app2.sh

    # GEONATURE
    sed -i "s/sudo rm -rf venv/#sudo rm -rf venv/" ./install_app2.sh 
    sed -i "s/ln -s /ln -sf /" ./install_app2.sh 
    sed -i 's|mkdir "src/external_assets"|mkdir -p "src/external_assets"|' ./install_app2.sh 
    sed -i '/.*install_gn_module.*/ s/$/ || true/' ./install_app2.sh
    
    # USERSHUB
    sed -i '/sudo a2enmod/d'  ./install_app2.sh

    # USERHUB/TAXHUB
    sed -i '/sudo -s supervisorctl/d'  ./install_app2.sh


    chmod +x install_app2.sh 

    ./install_app2.sh

    rm ./install_app2.sh

    echo $version_depot > /$script_home_dir/sysfiles/${application}_installed
    
    echo /$script_home_dir/sysfiles/${application}_installed
    cat /$script_home_dir/sysfiles/${application}_installed

    _verbose_echo "${green}launch_app - ${nocolor}Fin de l'installation de l'application ${application} ${version_depot}"

else
    source ${APP_HOME}/${BACKEND_DIR}/venv/bin/activate 

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
        export PGPASSWORD=${user_pg_pass}; psql -h ${db_host} -d ${db_name} -U ${user_pg} -p ${db_port} -f $file >> $update_db_log 2>> $update_db_log
    done

    cat $update_db_log | grep -i ERR || true


    # mise à jour des applications

    # frontend

    cd ${APP_HOME}/${FRONTEND_DIR}    
    export NVM_DIR="$HOME/.nvm"
    . "$NVM_DIR/nvm.sh" || true  # This loads nvm
    nvm install
    nvm use
    npm ci --only=prod
 
    if [ "$application" = "geonature" ]; then
        geonature update_configuration --build=false
        geonature generate_frontend_modules_route
        geonature generate_frontend_tsconfig_app
        geonature generate_frontend_tsconfig
        geonature update_module_configuration occtax --build=false
        geonature update_module_configuration validation --build=false
        geonature update_module_configuration occhab --build=false
        geonature frontend_build
    fi

    # backend

    cd ${APP_HOME}/${BACKEND_DIR}
    pip install -r requirements.txt # ?? upgrade ??
    if [ "$applicaiton" = "geonature" ]; then
        for D in $(find ../external_modules  -type l | xargs readlink) ; do
            # si le lien symbolique exisite
            if [ -e "$D" ] ; then
                cd ${D}
                cd backend   
                if [ -f 'requirements.txt' ]
                then
                    pip install -r requirements.txt
                fi
            fi
        done
    fi

    _verbose_echo "${green}launch_app - ${nocolor}Fin de la mise à jour de l'application ${application} ${version_installee} -> ${version_depot}"
    
    echo $version_depot > /$script_home_dir/sysfiles/${application}_installed

fi


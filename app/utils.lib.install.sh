#!/bin/bash
# set env for depot
function set_env_depot
{
    name=$1

    name_file=$bootstrap_dir/depots/${name}.ini
    . $name_file

    for v in $(cat $name_file);
    do
        v=${v%=*}
        export v=${!v}
    done
}


function manage_assets 
{
    name=$1
    set_env_depot $name

    if [ "$DEPOT_TYPE" = "application" ]; then
        cp ${bootstrap_dir}/${name}.settings.ini $script_home_dir/$name/$CONFIG_DIR/settings.ini
    fi

    if [ "$name" = "geonature" ]; then
        geonature_config=$script_home_dir/$name/$CONFIG_DIR/geonature_config.toml
        cp ${bootstrap_dir}/geonature_config.toml $geonature_config
        . $script_home_dir/$name/$CONFIG_DIR/settings.ini

        sed -i "s|SQLALCHEMY_DATABASE_URI.*|SQLALCHEMY_DATABASE_URI = 'postgresql://${user_pg}:${user_pg_pass}@${db_host}:${db_port}/${db_name}'|" $geonature_config
        sed -i "s|URL_APPLICATION.*|URL_APPLICATION = '${GEONATURE_PROTOCOL}://${GEONATURE_DOMAIN}/geonature'|" $geonature_config
        sed -i "s|API_ENDPOINT.*|API_ENDPOINT = '${GEONATURE_PROTOCOL}://${GEONATURE_DOMAIN}/geonature/api'|" $geonature_config
        sed -i "s|API_TAXHUB.*|API_TAXHUB = '${GEONATURE_PROTOCOL}://${GEONATURE_DOMAIN}/taxhub/api'|" $geonature_config
        sed -i "s/LOCAL_SRID.*/LOCAL_SRID = '${srid_local}'/" $geonature_config
    fi

}

# 
# ARGS
#   $1: depot
#   $2: version
function install_or_update
{
    name_version=$1

    name=${name_version%-*}
    version_voulue=$(get_version $name)


    set_env_depot $name

    get_depot_git $name $version_voulue

    manage_assets $name

    version_installed=$(get_version_installed $name)
    
    if [ "$version_installed" = "$version_voulue" ]; then 

        _verbose_echo "${green}launch_app - ${nocolor}Application ${name} ${version_voulue} Version inchangée"
        return 0


    # Installation

    elif [ -z "$version_installed" ]; then

        _verbose_echo "${green}launch_app - ${nocolor}Installation ${DEPOT_TYPE} ${name} ${version_voulue}"
        [[ "$DEPOT_TYPE" = "application" ]] && install_application $name;
        [[ "$DEPOT_TYPE" = "module_geonature" ]] && install_module_geonature $name;
        [[ "$DEPOT_TYPE" = "module_monitoring" ]] && install_module_monitoring $name;
        
        _verbose_echo "${green}launch_app - ${nocolor}Fin Installation ${DEPOT_TYPE} ${name} ${version_voulue}"

    # Mise à jour

    else

        _verbose_echo "${green}launch_app - ${nocolor}Mise à jour ${DEPOT_TYPE} ${name} ${version_voulue}"
        # [[ "$DEPOT_TYPE" = "application" ]] && update_application $name;
        # [[ "$DEPOT_TYPE" = "module_geonature" ]] && install_module $name;
        _verbose_echo "${green}launch_app - ${nocolor}Fin mise à jour ${DEPOT_TYPE} ${name} ${version_voulue}"
    
    fi

    set_version_installed $name $version_voulue    
}

# ARGS
#   $1 : name
function install_application 
{
    name=$1
    version_voule=$(get_version $name)

    cd $script_home_dir/$name/$INSTALL_DIR

    echo 'set -e' > ./install_app2.sh
    if $DEBUG; then 
        echo 'set -x' >> ./install_app2.sh
    fi

    cat ./install_app.sh >> ./install_app2.sh

 
    # GEONATURE
    sed -i 's|rm config/geonature_config.toml|a=a #rm config/geonature_config.toml|' ./install_app2.sh
    sed -i 's|cp config/geonature_config.toml.sample config/geonature_config.toml.*|[[ ! -f config/geonature_config.toml ]] \&\& cp config/geonature_config.toml.sample config/geonature_config.toml|' ./install_app2.sh 
    sed -i 's|cp config/geonature_config.toml.sample config/geonature_config.toml.*|[[ ! -f config/geonature_config.toml ]] \&\& cp config/geonature_config.toml.sample config/geonature_config.toml|' ./install_app2.sh 
    sed -i "s/sudo rm -rf venv/#sudo rm -rf venv/" ./install_app2.sh 
    sed -i "s/ln -s /ln -sf /" ./install_app2.sh 
    sed -i 's|mkdir "src/external_assets"|mkdir -p "src/external_assets"|' ./install_app2.sh 
    sed -i '/.*install_gn_module.*/ s/$/ || true/' ./install_app2.sh
    
    # USERSHUB
    sed -i '/sudo a2enmod/d'  ./install_app2.sh
 
    # USERHUB/TAXHUB
    sed -i '/sudo -s supervisorctl/d'  ./install_app2.sh

    chmod +x install_app2.sh 
    mkdir -p $script_home_dir/$name/$LOG_DIR
    touch $script_home_dir/$name/$LOG_DIR/test.log
    ./install_app2.sh

    rm ./install_app2.sh

}

function install_module_monitoring
{
    name=$1
    . $script_home_dir/geonature/config/settings.ini
    source $script_home_dir/geonature/backend/venv/bin/activate
    flask monitorings install $script_home_dir/monitoring/$DIR_SOUS_MODULE $name
}

function install_module_geonature 
{
    name=$1
    . $script_home_dir/geonature/config/settings.ini
    # export PGPASSWORD=${user_pg_pass};psql -h ${db_host} -d ${db_name} -U ${user_pg} -p ${db_port} -c "
    #     DROP SCHEMA IF EXISTS gn_imports CASCADE;
    #     DROP SCHEMA IF EXISTS gn_import_archives CASCADE;
    #     SELECT * FROM gn_commons.t_modules;
    #     DELETE FROM gn_commons.t_modules WHERE module_code='IMPORT'
    # "
    source $script_home_dir/geonature/backend/venv/bin/activate
    geonature install_gn_module $script_home_dir/$name $name --build=false # || re_install_gn_module $name
    export rebuid_for_module=1
}

function re_install_gn_module
{
    name=$1
    source $script_home_dir/geonature/backend/venv/bin/activate
    # test MODULE CODE ??
    # ln -s
    # toml
    # route ?
    # gnModule.ts ?
    # npm
    # pip install
}


function update_geonature_module
{
    name=$1
    echo update geonature_module TODO!!!
}


function update_db 
{
    name=$1
    version_installed=$(get_version_installed $name)
    version_voulue=$(get_version $name)

    _verbose_echo "Mise à jour BDD $version_installed to $version_voulue"

    . $script_home_dir/$name/$CONFIG_DIR/settings.ini

    echo migration_db_list_files $version_installed $version_voulue $script_home_dir/$name/$UPDATE_DB_DIR
    migration_db_list_files $version_installed $version_voulue $script_home_dir/$name/$UPDATE_DB_DIR

    update_db_log=$script_home_dir/$name/$LOG_DIR/migrate_db_${version_installed}to${version_voulue}.log
    rm -f $update_db_log

    for file in $(migration_db_list_files $version_installed $version_voulue $script_home_dir/$name/$UPDATE_DB_DIR)
    do
        echo "$file"
        export PGPASSWORD=${user_pg_pass}; psql -h ${db_host} -d ${db_name} -U ${user_pg} -p ${db_port} -f $file >> $update_db_log 2>> $update_db_log
    done

    cat $update_db_log | grep -i ERR || true

}


function update_application
{
    _verbose_echo "${green}launch_app - ${nocolor}Mise à jour ${DEPOT_TYPE} ${application} ${version_installed} -> ${version_voulue}"

    name=$1

    source $script_home_dir/$name/${BACKEND_DIR}/venv/bin/activate 

    # db
    update_db $name

    # frontend

    cd $script_home_dir/$name/${FRONTEND_DIR}    
    export NVM_DIR="$HOME/.nvm"
    . "$NVM_DIR/nvm.sh" || true  # This loads nvm
    nvm install
    nvm use
    npm ci --only=prod
 
    if [ "$name" = "geonature" ]; then
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

    cd $script_home_dir/$name/${BACKEND_DIR}
    pip install -r requirements.txt # ?? upgrade ??
    if [ "$name" = "geonature" ]; then
        # ?? dans update module ?????
        for D in $(find ../external_modules  -type l | xargs readlink) ; do
            # si le lien symbolique exsite
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

    _verbose_echo "${green}launch_app - ${nocolor}Fin de la mise à jour de l'application ${application} ${version_installed} -> ${version_voulue}"    
}


# ARG   
#   $1 name
#   $1 version
function set_version_installed
{
    name=$1
    version_installed=$2
    depot_file=$script_home_dir/sysfiles/${name}_installed
    echo $version_installed > $depot_file
}

# ARG   $1 name
function get_version
{
    name=$1
    for name_version in $(echo $APPLICATIONS $MODULES_GEONATURE $MODULES_MONITORING)
    do
      test="$(echo $name_version | grep $name)"
      if [ ! -z "$test" ]; then
        echo ${name_version#*-}
        return 0
      fi
    done
}


# ARG   $1 name
function get_version_installed
{
    name=$1

    version_installed=''
    depot_file=$script_home_dir/sysfiles/${name}_installed
    if [ -f $depot_file ]; then
        version_installed=$(cat $depot_file) 
    fi

    echo $version_installed;
    
}


# recupération d'un depot et mise à la bonne version
function get_depot_git
{
    cur=$(pwd)

    name=$1
    version=$2

    set_env_depot $name # récupère DEPOT_GIT

    dir_depot=$script_home_dir/$name

    if [ -d "${dir_depot}" ] && [ ! -d "${dir_depot}/.git" ]; then
        rm -R ${dir_depot}
    fi

    if [[ ! -d "${dir_depot}" ]]; then
        git clone ${DEPOT_GIT} -b ${version} --single-branch --depth=1 ${dir_depot}
    else
        cd $dir_depot
        # test si la branche existe
        if git rev-parse --verify ${version}; then
            git checkout ${version};
            if git show-ref --verify --quiet refs/tags/${version}; then
                a=1 # pass
            else
                git pull origin ${version} --depth=1;
            fi
        else
            git fetch origin ${version}:${version} --depth=1;
            git checkout ${version};
        fi 
        cd $cur
    fi
}


# liste les fichiers de migrations à jouer entre deux version pour une appli
# ARGS :    
#   $1 : version installee
#   $2 : version objectif
#   $3 : chemin (absolu) vers le repertoire contenant les fichiers de migration
# return (echo) : liste des fichiers
function migration_db_list_files 
{
    version_cur=$1
    version_target=$2
    migration_data_dir=$3

    tags=$(git ls-remote --tags 2>/dev/null | awk '{print $2}' | sed -s 's#refs/tags/##' | grep -v 'rc' )

    test_cur=$(echo $tags | grep "$version_cur")
    test_target=$(echo $tags | grep "$version_target")

    if [ -z "$test_cur" ] ; then
        exit 1
        echo Version cur $version_cur non ok
        echo $tags
    fi

    if [ -z "$test_target" ] ; then
        exit 1
        echo _version target $version_target non ok
        echo $tags
    fi

    test_cur=''
    test_target=''
    res=''

    for t in $tags
    do
        if [ "$t" = "$version_cur" ]; then
            test_cur=1
        fi

        if   [ ! -z "$test_cur" ] \
            && [ -z "$test_target" ] \
            && [ ! -z "$t_prev" ] \
            && inter="$(ls $migration_data_dir/*${t_prev}to${t}*.sql 2> /dev/null)" \
            ;  then
                echo $inter
        fi  

        if [ "$t" = "$version_target" ]; then
            test_target=1
        fi

        if [ ! -z ${test_cur} ]; then
            t_prev=$t
        fi
    done
}
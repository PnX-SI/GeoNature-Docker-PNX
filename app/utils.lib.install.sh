#!/bin/bash

# Fonctions pour l'installation et la mise à jour des applications, modules et module_monitoring


# Function qui met en variable d'environnement les caractéristiques du dept
# lus depuis le fichier $bootstrap_dir/depots/${name}.ini
#
# ARG :
#   $1 : name, nom du depot
#
function set_env_depot
{
    name=$1

    
    # lecture de la configuration du depot

    . $bootstrap_dir/depots/${name}.ini

    for v in $(cat $name_file);
    do

        v=${v%=*}
    
        # ici ${!v} donne la valeur de la variable dont le nom est $v
    
        export v=${!v}
    
    done
}

# fonction pour gérer les assets présents dans le fichier ${bootstrap_dir} :
#
# - les fichier settings.ini des applications
# - GEONATURE : geonature_config.toml
# 
# ARG :
#   $1 : name, nom du depot
#

function manage_assets 
{
    set -e 
    name=$1

    # on récupère CONFIG_DIR

    set_env_depot $name 

    # copie des settings.ini pour les applications

    if [ "$DEPOT_TYPE" = "application" ]; then
        cp ${bootstrap_dir}/${name}.settings.ini $script_home_dir/$name/$CONFIG_DIR/settings.ini
    fi

    # geonature_config.toml et config.py traitement communs ..???..
    # on renseigne ce qui peut l'être depuis le fichier settings.ini
    # SQLALCHEMY_DATABASE_URI, URL_APPLICATION, etc...

    file_config=""
    file_bootstrap=""

    if [ "$name" = "geonature" ]; then    
        file_config=$script_home_dir/$name/$CONFIG_DIR/geonature_config.toml
        file_bootstrap=${bootstrap_dir}/geonature_config.toml
    elif echo "usershub taxhub atlas" | grep $name; then
        file_config=$script_home_dir/$name/$CONFIG_DIR/config.py
        file_bootstrap=${bootstrap_dir}/${name}.config.py
    fi

    if [ ! -z "$file_config" ] && [ -f "$file_bootstrap" ]; then
        cp $file_bootstrap $file_config
        . $script_home_dir/$name/$CONFIG_DIR/settings.ini
        sed -i "s|SQLALCHEMY_DATABASE_URI.*|SQLALCHEMY_DATABASE_URI = 'postgresql://${user_pg}:${user_pg_pass}@${db_host}:${db_port}/${db_name}'|" $file_config
        sed -i "s|URL_APPLICATION.*|URL_APPLICATION = '${GEONATURE_PROTOCOL}://${GEONATURE_DOMAIN}/$name'|" $file_config
        sed -i "s|API_ENDPOINT.*|API_ENDPOINT = '${GEONATURE_PROTOCOL}://${GEONATURE_DOMAIN}/geonature/api'|" $file_config
        sed -i "s|API_TAXHUB.*|API_TAXHUB = '${GEONATURE_PROTOCOL}://${GEONATURE_DOMAIN}/taxhub/api'|" $file_config
        sed -i "s/LOCAL_SRID.*/LOCAL_SRID = '${srid_local}'/" $file_config
    fi

}


# fonction qui procède à l'installation ou a la mise à jour
# des application ou module
# on compare la version installée à la version spécifiée dans le .env
# afin de déterminer les actions à effectuer
#
# ARGS
#   $1: name_version de la forme '<name>-x.x.x'
#
# par exemple 
#
# install_or_update geonature-2.6.2
#
function install_or_update
{
    name_version=$1

    # recupération du nom depuis name_version

    name=${name_version%-*}

    # recupération des version voulue et installée

    version_voulue=$(get_version $name)
    version_installed=$(get_version_installed $name)

    # recupération de la config du depot

    set_env_depot $name

    # récupération ou mise à jour des codes du dépot par git

    get_depot_git $name $version_voulue


    # gestion des assets (config pour l'instant)

    manage_assets $name

    # actions    

    if [ "$version_installed" = "$version_voulue" ]; then 

        # Si pas de changement, on ne fait rien

        _verbose_echo "${green}launch_app - ${nocolor} ${DEPOT_TYPE} ${name} ${version_voulue} Version inchangée"
        return 0

    elif [ -z "$version_installed" ]; then

        # Si pas de version installée
        # -> on procède à l'installation, selon le type du depot (DEPOT_TYPE)

        _verbose_echo "${green}launch_app - ${nocolor}Installation ${DEPOT_TYPE} ${name} ${version_voulue}"
        [[ "$DEPOT_TYPE" = "application" ]] && install_application $name;
        [[ "$DEPOT_TYPE" = "module_geonature" ]] && install_module_geonature $name;
        [[ "$DEPOT_TYPE" = "module_monitoring" ]] && install_module_monitoring $name;
        
        _verbose_echo "${green}launch_app - ${nocolor}Fin Installation ${DEPOT_TYPE} ${name} ${version_voulue}"

    else

        # Sinon, on est dans le cas : 
        # version_installée != version_voulue
        # on procède à la mise à jour (TODO)

        _verbose_echo "${green}launch_app - ${nocolor}Mise à jour ${DEPOT_TYPE} ${name} ${version_installed} -> ${version_voulue}"
        [[ "$DEPOT_TYPE" = "application" ]] && update_application $name;
        [[ "$DEPOT_TYPE" = "module_geonature" ]] && update_module_geonature $name;
        [[ "$DEPOT_TYPE" = "module_monitoring" ]] && update_module_monitoring $name;
        _verbose_echo "${green}launch_app - ${nocolor}Fin mise à jour ${DEPOT_TYPE} ${name} ${version_installed} -> ${version_voulue}"
    
    fi

    # Mise à jour du numéro de version installée
    # (dans le fichier $script_home_dir/sysfiles/installed/${name})

    set_version_installed $name $version_voulue    
}


# fonction qui procède à l'installation d'une applicatipon
#
# Ici on modifie le fichier install_app.sh : 
# - on ajoute set -e pour forcer le script à s'arrêter en cas d'erreur
# - on modifie le fichier install_app.sh afin de
#  - supprimer les erreurs
#  - enlever la gestion de supervisor et apache
#
# ARGS
#   $1 : name : nom de l'application
#
function install_application
{
    name=$1

    # récupération de la version voulue et de la config du depot

    version_voule=$(get_version $name)
    set_env_depot $name

    # on se place dans le répertoire qui contient install_app.sh

    cd $script_home_dir/$name/$INSTALL_DIR

    # pour forcer l'arret du scrit en cas d'erreur

    echo 'set -e' > ./install_app2.sh

    # affichage des commande (en mode DEBUG)

    if $DEBUG; then 
        echo 'set -x' >> ./install_app2.sh
    fi


    # copie du fichier install_app.sh pour ppouvoir le modifier

    cat ./install_app.sh >> ./install_app2.sh
 
    # GEONATURE
    sed -i 's|rm config/geonature_config.toml|a=a #rm config/geonature_config.toml|' ./install_app2.sh
    sed -i 's|cp config/geonature_config.toml.sample config/geonature_config.toml.*|[[ ! -f config/geonature_config.toml ]] \&\& cp config/geonature_config.toml.sample config/geonature_config.toml|' ./install_app2.sh 
    sed -i 's|cp config/geonature_config.toml.sample config/geonature_config.toml.*|[[ ! -f config/geonature_config.toml ]] \&\& cp config/geonature_config.toml.sample config/geonature_config.toml|' ./install_app2.sh 
    sed -i "s/sudo rm -rf venv/#sudo rm -rf venv/" ./install_app2.sh 
    sed -i "s/ln -s /ln -sf /" ./install_app2.sh 
    sed -i 's|mkdir "src/external_assets"|mkdir -p "src/external_assets"|' ./install_app2.sh 
    sed -i '/.*install_gn_module.*/ s/$/ || true/' ./install_app2.sh 
    sed -i 's/npm run build/#npm run build/' ./install_app2.sh
    sed -i 's/npm ci --only=prod/npm ci --only=prod; npm install protractor;/' ./install_app2.sh

    # USERSHUB
    sed -i '/sudo a2enmod/d'  ./install_app2.sh
    # USERHUB/TAXHUB
    sed -i '/sudo -s supervisorctl/d'  ./install_app2.sh

    mkdir -p $script_home_dir/$name/$LOG_DIR
    touch $script_home_dir/$name/$LOG_DIR/test.log

    # execution du script d'installation

    chmod +x install_app2.sh 
    ./install_app2.sh

    rm ./install_app2.sh

    # sauvegarde de supervisord
    sudo cp /etc/supervisor/conf.d/* ${script_home_dir}/sysfiles/supervisor/


}

# Fonction qui procède à l'installation d'un module géonature
#
# le build du frontend est différé pour ne pas le refaire à chaque installation de module
#
# ARG :
#   $1 : name (nom du module)
#
function install_module_geonature 
{
    name=$1

    # Activation du Virtualenv
    
    source $script_home_dir/geonature/backend/venv/bin/activate

    # installation du module
    
    geonature install_gn_module $script_home_dir/$name $name --build=false

    # pour executer le build du frontend de geonature apres l'installation des modules

    export build_geonature_frontend=1
}

# Fonction qui procède à l'installation d'un sous-module de suivi
#
# le build du frontend est différé pour ne pas le refaire à chaque installation de module
#
# ARG :
#   $1 : name (nom du module)
#
function install_module_monitoring
{
    name=$1
 
    # Activation du Virtualenv (pour etre sur que la commande flask monitorings soit prise en compte)
    source $script_home_dir/geonature/backend/venv/bin/activate
    deactivate
    source $script_home_dir/geonature/backend/venv/bin/activate

    # Installation du sous module
    cd $script_home_dir/geonature/backend
    flask
    flask monitorings install $script_home_dir/$name/$DIR_SOUS_MODULE $name --build=false
 
    # pour executer le build du frontend de geonature apres l'installation des modules

    export build_geonature_frontend=1

}

function update_module_monitoring
{
    name=$1
    export build_geonature_frontend=1
}


# Update d'un module TODO
#
function update_module_geonature
{
    name=$1
    echo update geonature_module TODO!!!

    # bdd
    update_db $name       

    # frontend
    cd ${script_home_dir}/geonature/frontend
    package=${script_home_dir}/${name}/frontendpackage.json
    if [ -f "$package" ]; then
        npm install --no-save $package
    fi

    # backend
    source ${script_home_dir}/geonature/backend/venv/bin/activate
    requierements=${script_home_dir}/${name}/requierements.txt
    if [ -f "$requierements" ]; then
        pip install -r $requierements
    fi

    export build_geonature_frontend=1

}


# Cette function liste et execute les fichiers sql qu'il faut jouer pour passer d'une version à l'autre
#
# ARG : $1 : name
#
function update_db 
{
    name=$1

    # récupération de la config du dépot (CONFIG_DIR, UPDATE_DB_DIR, LOG_DIR)

    set_env_depot $name

    # récupération version_installée / version_voulue

    version_installed=$(get_version_installed $name)
    version_voulue=$(get_version $name)

    _verbose_echo "Mise à jour BDD $DEPOT_TYPE $name $version_installed to $version_voulue"

    # fichier log pour la migration

    update_db_log=$script_home_dir/$name/$LOG_DIR/migrate_db_${version_installed}to${version_voulue}.log

    echo "Migration BDD pour ${DEPOT_TYPE} ${name} ${version_installee} -> ${version_voulue}" > $update_db_log
        
    . $script_home_dir/geonature/config/settings.ini

    for file in $(migration_db_list_files $name $version_installed $version_voulue)
    do
        # pour les fichiers nécessaires pour la migration
        echo "$file"

        # recupération des paramètres de connexion à la base (depuis GN settings.ini)
        
        
        # execution du fichier ????
        
        export PGPASSWORD=${user_pg_pass}; psql -h ${db_host} -d ${db_name} -U ${user_pg} -p ${db_port} -f $file >> $update_db_log 2>> $update_db_log
    done

    err=$(cat $update_db_log | grep -i ERR || true)

    if [ ! -z "$err" ]; then
        _verbose_echo  "Erreur migration $DEPOT_TYPE $name $version_installed to $version_voulue"
        _verbose_echo "$err"
        exit 0
    fi

}


# fonction pour re-lancer la configuration et le build du frontend de geonature
#
function geonature_up_config_and_build
{   
        set -e

        # Activation du virtualenv
        source $script_home_dir/geonature/backend/venv/bin/activate 

        # Configuration de geonature
        geonature update_configuration --build=false --prod=false
        geonature generate_frontend_modules_route
        geonature generate_frontend_tsconfig_app
        geonature generate_frontend_tsconfig


        # configuration des modules
        for module in  $(ls $script_home_dir/geonature/external_modules) ; do
            # si le lien symbolique exsite
                    geonature update_module_configuration ${module} --build=false  --prod=false
        done

        # rebuild du frontend

        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || true # This loads nvm

        cd $script_home_dir/geonature/frontend
        echo "Build du frontend..."
        npm run build
}


# Fonction pour la mise à jour d'une application
# TODO
#
function update_application
{
    name=$1

    # db    
    # update_db $name

    # frontend - installation des paquets nvm

    cd $script_home_dir/$name/${FRONTEND_DIR}    
    export NVM_DIR="$HOME/.nvm"
    . "$NVM_DIR/nvm.sh" || true  # This loads nvm
    nvm install
    nvm use
    npm ci --only=prod
 
    if [ "$name" = "geonature" ]; then
        # geonature frontend_build
        export build_geonature_frontend=1
    fi

    # backend

    source $script_home_dir/$name/${BACKEND_DIR}/venv/bin/activate 

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

}


# Fonction qui permet de stocker le numero de version installé pour une application ou un module
#
# elle écrit le numero de version installé dans le fichier
# $script_home_dir/sysfiles/installed/${name}
#
# ARG   
#   $1 name
#   $1 version_installed
#
function set_version_installed
{
    name=$1
    version_installed=$2
    
    mkdir -p $script_home_dir/sysfiles/installed
    
    depot_file=$script_home_dir/sysfiles/installed/${name}
    
    echo $version_installed > $depot_file
}

# fonction qui récupère la version voulue pour une application ou un module
#
#  depuis les version renseignées dans le .env
#
# ARG   $1 name
#
function get_version
{
    name=$1

    # on cherche parmis les eleements de ALL_DEPOT celui qui correspond à name
    # et l'on renvoie la version associée

    for name_version in $(echo $ALL_DEPOTS)
    # un element name_version de ALL_DEPOT est de la forme name-x.x.x
    do

      test="$(echo $name_version | grep $name)"
      
      if [ ! -z "$test" ]; then
        
        # ici ${name_version#*-} donne tout ce qui se trouve apres le tiret -
        # soit la version
        echo ${name_version#*-}
        return 0

      fi

    done
}

# Fonction qui renvoie la version installée d'une application ou d'un module
# stockée dans le fichier $script_home_dir/sysfiles/installed/${name}
#
# ARG   $1 name
function get_version_installed
{
    name=$1

    version_installed=''

    depot_file=$script_home_dir/sysfiles/installed/${name}

    if [ -f $depot_file ]; then

        version_installed=$(cat $depot_file) 

    fi

    echo $version_installed;
    
}


# recupération d'un depot et mise à la bonne version
# les information d'un depot sont présent dans le fichier <bootstrap_files>/depots/<name>.ini
# et récupérés en variable d'environnement par la fonction set_env_depot $name
#
# ARGS :
#   $1 : nom du depot
function get_depot_git
{
    cur=$(pwd)

    name=$1
    version=$2

    set_env_depot $name # récupère DEPOT_GIT

    dir_depot=$script_home_dir/$name

    # si le repertoire n'a pas de .git on le supprime
    # ?? faire un exit dan ce cas et forcer la suppression à la main

    if [ -d "${dir_depot}" ] && [ ! -d "${dir_depot}/.git" ]; then
        rm -R ${dir_depot}
    fi

    if [[ ! -d "${dir_depot}" ]]; then
    
        # si le repertoire n'existe pas
        # -> on clone le répertoire (avec depth=1 pour gagner du temps (cf GeoNature obèse))

        git clone ${DEPOT_GIT} -b ${version} --single-branch --depth=1 ${dir_depot}

    else

        # si le répertoire existe déja
        # on se place dedans

        cd $dir_depot
        
        if git rev-parse --verify ${version} -q > /dev/null; then

            # si la branche à déja été récupérée
            # -> checkout vers cette branche
            
            git checkout ${version} -q;
            
            # recupération des dernières modifications si besoin (sans --depth=1 sinon erreur)
            
            git pull origin ${version} -q;

        else

            # si la branche n'existe pas, on la récupère avec fetch

            git fetch origin ${version}:${version} --depth=1 -q;

            # puis checkout vers cette branche
            
            git checkout ${version} -q;

        fi 

        cd $cur

    fi
}


# liste les fichiers de migrations à jouer entre deux version pour une appli
#
# conçu pour les tags et non les branches ..
#
# ARGS :    
#   $1 : name
#   $1 : version installee
#   $2 : version voulue
# return (echo) : liste des fichiers
#
function migration_db_list_files 
{
    name=$1
    version_installed=$2
    version_voulue=$3

    set_env_depot $name

    # répertoire contenant les fichiers de migration

    migration_data_dir=$script_home_dir/$name/$UPDATE_DB_DIR

    # liste des tags
    cd $script_home_dir/$name
    tags=$(git ls-remote --tags 2>/dev/null | awk '{print $2}' | sed -s 's#refs/tags/##' | grep -v 'rc' )

    # test si version installée et version voulue sont bien dans les tags
    # sinon on sort

    test_installed=$(echo $tags | grep "$version_installed")
    test_voulue=$(echo $tags | grep "$version_voulue")

    if [ -z "$test_installed" ] ; then
        exit 1
        echo Version cur $version_installed non ok
        echo $tags
    fi

    if [ -z "$test_voulue" ] ; then
        exit 1
        echo _version target $version_voulue non ok
        echo $tags
    fi

    # Boucle sur les tags pour récupérer les fichiers à jouer

    test_installed='' # si on a passé la version installée
    test_voulue='' # si on a atteind la version voulue
    res=''

    for t in $tags
    do

        if [ "$t" = "$version_installed" ]; then
            # si on a passé la version installée
            test_installed=1
        fi

        if   [ ! -z "$test_installed" ] \
            && [ ! -z "$t_prev" ] \
            && inter="$(ls $migration_data_dir/*${t_prev}*${t}*.sql 2> /dev/null)" \
            ;  then
            # si 
            # - on a passé la tag installé
            # - on a un précédent (on est)
            # - on a bien un fichier 
                echo $inter
        fi  

        if [ "$t" = "$version_voulue" ]; then
            # test si on arrive au tag voulu
            # arret de la boucle
            test_voulue=1
            break
        fi

        if [ ! -z ${test_installed} ]; then

            # si on a passe le tag installé
            # le tag en cours devient le précdent

            t_prev=$t
        fi
    done
}


# fonction qui procède à l'installation de la base de données
#
# ici on éxcute le script installl_db.sh de geonature
# avec quelques modifications pour le rendre compatible avec l'environnement
#
# - on remplace les commandes en sudo -u postgres
#
# à réfléchir, par exemple comment stocker la version de base ?
# ici égale à la version de géonature
# comment prendre en compte les version des applications et modules
#
# TODO Atlas
# 
function install_db {

    # récupération des codes de geonature

    get_depot_git geonature $(get_version geonature)
    
    log_file_install_db=$script_home_dir/geonature/var/log/install_db.log

    # reinit log
    rm -f $log_file_install_db
    mkdir -p $script_home_dir/geonature/var/log
    touch $log_file_install_db

    # recupération de settings.ini pour les accès à la base

    manage_assets geonature
    . $script_home_dir/geonature/config/settings.ini

    # on se place dans le répertoire d'installation de GN

    cd $script_home_dir/geonature/install

    # récupération des version de TaxHub UsersHub 

    cat $script_home_dir/geonature/config/settings.ini.sample | grep release > /$script_home_dir/geonature/config/release.ini
    cat /$script_home_dir/geonature/config/release.ini
    . /$script_home_dir/geonature/config/release.ini

    # exit en cas d'erreur
    echo "set -e;" > ./install_db_2.sh

    # affichage des commandes si DEBUG
    if $DEBUG; then 
        echo 'set -x' >> ./install_db_2.sh
    fi

    # fichier install_db_2.sh :

    # commandes pratiques

    echo "export PGPASSWORD=$user_pg_pass; 
psqla='psql -h ${db_host} -d ${db_name} -U ${user_pg} -p ${db_port}';
psqlg='psql -h ${db_host} -d postgres -U ${user_pg} -p ${db_port}'; 
" >> ./install_db_2.sh

    # copie du fichier

    cat ./install_db.sh >> ./install_db_2.sh

    # remplacement jusqu'à la suppresion des erreurs
    
    sed -i '/^check_superuser$/d' ./install_db_2.sh
    sed -i '/postgresql.conf/d' ./install_db_2.sh
    sed -i 's/if $drop_apps_db/echo $drop_apps_db; if $drop_apps_db/' ./install_db_2.sh
    sed -i 's/sudo -n -u postgres -s createdb.*/${psqlg} -c "CREATE DATABASE ${db_name};"/' ./install_db_2.sh    
    sed -i 's/sudo -u postgres -s dropdb.*/\
    query="SELECT pg_terminate_backend(pg_stat_activity.pid)\
    FROM pg_stat_activity WHERE pg_stat_activity.datname = '\'${db_name}\''\
    AND pid <> pg_backend_pid() ;"; ${psqlg} -c "${query}"; ${psqlg} -c "DROP DATABASE ${db_name};";/' ./install_db_2.sh    
    sed -i 's/sudo -n -u "postgres" -s dropdb.*/${psqlg} -c "DROP DATABASE ${db_name};"/' ./install_db_2.sh    
    sed -i 's/sudo -n -u postgres -s psql -d "${db_name}"/${psqla}/' ./install_db_2.sh
    sed -i 's/sudo -n -u postgres -s psql -d $db_name/${psqla}/' ./install_db_2.sh
    sed -i 's/sudo -u postgres -s psql -d $db_name/${psqla}/' ./install_db_2.sh
    sed -i 's/sudo -n -u "postgres" -s psql/${psqlg}/' ./install_db_2.sh
    sed -i 's/sudo -u postgres -s -- psql/$psqlg/' ./install_db_2.sh
    sed -i 's/unzip/unzip -n/' ./install_db_2.sh
    sed -i '/sudo service postgresql restart/d' ./install_db_2.sh
    
    # execution du script et mise à jour de la version de la base (ici geonature) 

    chmod +x ./install_db_2.sh
    . install_db_2.sh
    
    # verification des erreurs
    if cat $log_file_install_db | grep ERR; then
        cat $log_file_install_db | grep ERR
        _verbose_echo "${green}launch_app - ${nocolor}Erreur dans l'installation de la base de données..."
        _verbose_echo "${green}launch_app - ${nocolor}Veuillez relancer docker-compose pour finir l'installation si BDD ok"
        # exit 1; 
    fi 
    # version db geonature only ou pour tous ?????

    set_version_installed db $(get_version geonature)
}
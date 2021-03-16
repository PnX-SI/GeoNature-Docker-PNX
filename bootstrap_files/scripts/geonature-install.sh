set -e

application=$1
version_depot=$2
version_installee=$3

. /usr/local/utils.lib.sh




echo Geonature $version_installee $version_target

if [ -z "$version_installee" ]; then

    # installation 

    cd ${GN_HOME}/install 
    ./install_app.sh

    sudo cp /etc/supervisor/conf.d/*.conf ${script_home_dir}/sysfiles/supervisor/

else

    # mise à jour bdd

    echo Mise à jour BDD $version_installee to $version_depot
    for file in migration_db_list_files $version_installee $version_depot $GN_HOME/data/migrations
    do
        echo $file
        $psqla -f $file
    done

    # mise à jour des applications

    source ${GN_HOME}/venv/backend/bin/activate 
    
    cd ${GN_HOME}/backend
    pip install -r requirements.txt
    
    cd ../frontend
    nvm ci

    # config + build  frontend + redemarre l'appli
    geonature update_configuration

    # module ?????

fi
set -e

version_installee=$2
version_depot=$1

. /usr/local/utils.lib.sh

if [ -z "$version_installee" ]; then

    # installation 

    cd ${TH_HOME} 
    ./install_app.sh

    sudo cp /etc/supervisor/conf.d/*.conf ${script_home_dir}/sysfiles/supervisor/

else

    # mise à jour bdd

    echo Mise à jour BDD $version_installee to $version_depot
    for file in migration_db_list_files $version_installee $version_depot $TH_HOME/data/migrations
    do
        echo $file
        $psqla -f $file
    done

    # mise à jour des applications

    source ${TH_HOME}/venv/backend/bin/activate 
    
    cd ${TH_HOME}/backend
    pip install -r requirements.txt
   
    sudo supervisorctl restart usershub
    
    # module ?????

fi
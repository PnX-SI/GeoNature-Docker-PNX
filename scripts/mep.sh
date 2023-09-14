###
# script mise en place instance
###

# env
projects_directory=/applications/projets
project_name=geonature.guyane-parcnational.fr
project_path=${projects_directory}/${project_name}
git_repo=https://github.com/PnX-SI/Geonature-Docker-PNX
git_branch=current

# repertoire projet
git clone -b ${git_branch} ${git_repo} ${project_path}

# proxy (ou copie)
cp -r ${project_path}/rproxy ${projects_directory}/rproxy
# ln pour dev ?
# ln -s ${project_path}/rproxy ${projects_directory}/rproxy

#
cd ${projects_directory}/rproxy
# creer unfichier settings.ini
# avec HOST, NETWORK_TRAEFIK_GN_1, NETWORK_TRAEFIK_GN_2, HTTP_PROXY, etc ....
${project_path}/script/init_env_file.sh .env.exemple pag_dev.ini .env

# creer les reseaux
eval $(grep NETWORK_TRAEFIK_GN_1 ${projects_directory}/rproxy/.env)
eval $(grep NETWORK_TRAEFIK_GN_2 ${projects_directory}/rproxy/.env)
docker network create rpx_net
docker network create $NETWORK_TRAEFIK_GN_1
docker network create $NETWORK_TRAEFIK_GN_2

# lancement du proxy (TODO faire service)
cd ${projects_directory}/rproxy
docker compose up -d

# instance
cd $project_path
# créer un fichier settings.ini avec
# DOMAIN PROJECT_NAME PGADMIN_DEFAULT_EMAIL PGADMIN_DEFAULT_PASSWORD
# HTTP_PROXY HTTPS_PROXY
# SECRET_KEY ??
${project_path}/scripts/init_env_file.sh .env.example settings.ini .env

# rappatrier les fichiers dans data

# bdd (voir autre doc)


# mettre en place les crons
cron_script=${projects_directory}/nigth_cron.sh # à adapter si besoin de day_cron
touch $cron_script
chmod 775 $cron_script
echo "${project_path}/scripts/cron.sh" >> $cron_script
(crontab -l 2>/dev/null; echo "* 0 * * * ${scron_script}") | crontab -

# ftp
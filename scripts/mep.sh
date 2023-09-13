###
# script mise en place instance
###

# env
projects_directory=/applications/projets
project_name=geonature.guyane-parncational.fr
project_path=${projects_directory}/${project_name}
git_repo=https://github.com/PnX-SI/GeoNature-Docker
git_branch=current

# repertoire projet
git clone -b ${git_branch} ${git_repo} ${project_path}

# proxy (ou copie)
cp -r ${project_path}/rproxy ${projects_directory}/rproxy
# ln pour dev ?
# ln -s ${project_path}/rproxy ${projects_directory}/rproxy

# copie env proxy
cp ${projects_directory}/rproxy/.env.exemple ${projects_directory}/rproxy/.env
# editer HOST, NETWORK_TRAEFIK_GN_1, NETWORK_TRAEFIK_GN_2, HTTP_PROXY, etc ....

# creer les reseaux
eval $(grep NETWORK_TRAEFIK_GN_1 ${projects_directory}/rproxy/.env)
eval $(grep NETWORK_TRAEFIK_GN_2 ${projects_directory}/rproxy/.env)
docker network create rpx_net
docker network create $NETWORK_TRAEFIK_GN_1
docker network create $NETWORK_TRAEFIK_GN_2

# lancement du proxy (TODO faire service)
cd ${projects_directory}/rproxy
docker compose up -d
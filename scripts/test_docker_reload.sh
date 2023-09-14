source $1
error=""

./scripts/init_applications_config.sh $1
sleep 5s
docker compose logs geonature-backend | grep "Worker reloading" || error="${error} geonature-backend"
docker compose logs usershub | grep "Worker reloading" || error="${error} usershub"
docker compose logs taxhub | grep "Worker reloading" || error="${error} taxhub"
docker compose logs atlas | grep "Worker reloading" || error="${error} atlas"
docker compose logs geonature-worker | grep "worker: Warm shutdown" || error="${error} geonature-worker"

# check error
[ ! -z "$error" ] && echo "erreur reload ${error}" && exit 1 || exit 0

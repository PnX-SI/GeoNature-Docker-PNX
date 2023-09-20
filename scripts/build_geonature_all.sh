# script docker GN all
set -xeof pipefail

source $1
current_dir="$(pwd)"

# BUILD des applications

# - ATLAS

docker build -f sources/GeoNature-atlas/Dockerfile -t ${ATLAS_IMAGE}  sources/GeoNature-atlas/


# - USERSHUB

# chargement des sous modules git
cd sources/UsersHub
git submodule init
git submodule update
cd ${current_dir}

docker build -f sources/UsersHub/Dockerfile -t ${USERSHUB_IMAGE}  sources/UsersHub/


# - TAXHUB

# chargement des sous modules git
cd sources/TaxHub
git submodule init
git submodule update
cd ${current_dir}

docker build -f sources/TaxHub/Dockerfile -t ${TAXHUB_IMAGE}  sources/TaxHub/


# - GEONATURE

# chargement des sous modules git
cd sources/GeoNature
git submodule init
git submodule update
cd ${current_dir}

#   - FRONTEND

#     - SOURCES

docker build -f sources/GeoNature/frontend/Dockerfile -t ${GEONATURE_FRONTEND_IMAGE}-source --target=source sources/GeoNature/

#     - NGINX

docker build -f sources/GeoNature/frontend/Dockerfile -t ${GEONATURE_FRONTEND_IMAGE}-nginx --target=prod-base sources/GeoNature/

#     - APP + 4 MODULES

docker build \
    --build-arg GEONATURE_FRONTEND_IMAGE=${GEONATURE_FRONTEND_IMAGE} \
    -f ./build/Dockerfile-geonature-frontend \
    -t ${GEONATURE_FRONTEND_IMAGE} .

#  - BACKEND

#    - WHEELS

docker build -f sources/GeoNature/backend/Dockerfile -t ${GEONATURE_BACKEND_IMAGE}-wheels --target=wheels sources/GeoNature/

#    - APP

docker build \
    --build-arg GEONATURE_BACKEND_IMAGE=${GEONATURE_BACKEND_IMAGE} \
    -f ./build/Dockerfile-geonature-backend \
    -t ${GEONATURE_BACKEND_IMAGE} .

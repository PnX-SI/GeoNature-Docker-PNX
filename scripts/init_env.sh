#!/bin/bash

# destiné à l'action docker.yml


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPOSITORY_DIR=$(dirname "${SCRIPT_DIR}")

# récupération des infos git
. $SCRIPT_DIR/get_git_version.sh . GDS
. $SCRIPT_DIR/get_git_version.sh ./sources/GeoNature GN
. $SCRIPT_DIR/get_git_version.sh ./sources/gn_module_monitoring GN_MODULE_MONITORING
. $SCRIPT_DIR/get_git_version.sh ./sources/gn_module_export GN_MODULE_EXPORT
. $SCRIPT_DIR/get_git_version.sh ./sources/gn_module_import GN_MODULE_IMPORT
. $SCRIPT_DIR/get_git_version.sh ./sources/gn_module_dashboard GN_MODULE_DASHBOARD

cd $REPOSITORY_DIR/


# [ ${GDS_IS_TAG} = true ] && IMAGE_VERSION="${GDS_GIT_VERSION}__${GN_GIT_VERSION}" || IMAGE_VERSION="${GDS_GIT_VERSION}"
IMAGE_VERSION="${GDS_GIT_VERSION}"
[ ${GDS_IS_TAG} = true ] && LATEST_TAG=", latest" || LATEST_TAG=""

GN_IMAGE_NAME=ghcr.io/pnx-si/gdx-geonature

GN_FRONTEND_IMAGE=$(echo "${GN_IMAGE_NAME}-frontend:${GDS_GIT_VERSION}" | tr '[:upper:]' '[:lower:]')
GN_FRONTEND_TAGS="${GN_FRONTEND_IMAGE}${LATEST_TAG}"

GN_BACKEND_IMAGE=$(echo "${GN_IMAGE_NAME}-backend:${GDS_GIT_VERSION}" | tr '[:upper:]' '[:lower:]')
GN_BACKEND_TAGS="${GN_BACKEND_IMAGE}${LATEST_TAG}"

GN_DESCRIPTION="GDS ${GDS_GIT_VERSION} GeoNature ${GN_GIT_VERSION}, MONITORING ${GN_MODULE_MONITORING_GIT_VERSION}, IMPORT ${GN_MODULE_IMPORT_VERSION}, EXPORT ${GN_MODULE_EXPORT_GIT_VERSION}, DASHBOARD ${GN_MODULE_DASHBOARD_GIT_VERSION}"

UH_IMAGE_NAME=ghcr.io/pnx-si/gdx-usershub
UH_IMAGE=$(echo "${UH_IMAGE_NAME}:${GDS_GIT_VERSION}" | tr '[:upper:]' '[:lower:]')
UH_TAGS="${UH_IMAGE}${LATEST_TAG}"

TH_IMAGE_NAME=ghcr.io/pnx-si/gdx-taxhub
TH_IMAGE=$(echo "${TH_IMAGE_NAME}:${GDS_GIT_VERSION}" | tr '[:upper:]' '[:lower:]')
TH_TAGS="${TH_IMAGE}${LATEST_TAG}"

ATLAS_IMAGE_NAME=ghcr.io/pnx-si/gdx-atlas
ATLAS_IMAGE=$(echo "${ATLAS_IMAGE_NAME}:${GDS_GIT_VERSION}" | tr '[:upper:]' '[:lower:]')
ATLAS_TAGS="${ATLAS_IMAGE}${LATEST_TAG}"

BUILD_DATE=$(date -Iseconds)

GN_LABELS="org.opencontainers.image.url=https://github.com/PnX-SI/GeoNature-Docker-services
org.opencontainers.image.created=${BUILD_DATE}
org.opencontainers.image.source=https://github.com/PnX-SI/GeoNature
org.opencontainers.image.version=${GN_GIT_VERSION}
org.opencontainers.image.vendor=https://github.com/PnX-SI
"

echo "GDS_IS_TAG=$GDS_IS_TAG"
echo "GN_IS_TAG=$GN_IS_TAG"
echo "GN_MODULE_MONITORING_IS_TAG=$GN_MODULE_MONITORING_IS_TAG"
echo "GN_MODULE_EXPORT_IS_TAG=$GN_MODULE_EXPORT_IS_TAG"
echo "GN_MODULE_IMPORT_IS_TAG=$GN_MODULE_IMPORT_IS_TAG"
echo "GN_MODULE_DASHBOARD_IS_TAG=$GN_MODULE_DASHBOARD_IS_TAG"

echo "GN_FRONTEND_IMAGE=$GN_FRONTEND_IMAGE"
echo "GN_FRONTEND_TAGS=$GN_FRONTEND_TAGS"

echo "GN_BACKEND_IMAGE=$GN_BACKEND_IMAGE"
echo "GN_BACKEND_TAGS=$GN_BACKEND_TAGS"

echo "GN_DESCRIPTION=$GN_DESCRIPTION"
echo "GN_LABELS=$GN_LABELS"
echo "BUILD_DATE=$BUILD_DATE"

echo "UH_TAGS=$UH_TAGS"
echo "TH_TAGS=$TH_TAGS"
echo "ATLAS_TAGS=$ATLAS_TAGS"


. $SCRIPT_DIR/check_env.sh
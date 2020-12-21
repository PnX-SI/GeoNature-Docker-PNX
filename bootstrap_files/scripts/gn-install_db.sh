#!/bin/bash

. /usr/local/utils.lib.sh

verbose=1
mkdir -p ${GN_HOME}/tmp/{geonature,taxhub,nomenclatures,usershub}

#include user config = settings.ini
. ${GN_HOME}/config/settings.ini

LOG_DIR=${GN_HOME}/var/log

export PGPASSWORD=$user_pg_pass

cd ${GN_HOME}

# Mise en place de la structure de la base et des données permettant son fonctionnement avec l'application
_verbose_echo "${green}Geonature - ${nocolor}Mise en place de la structure de la base et des données permettant son fonctionnement avec l'application"
cp data/grant.sql tmp/geonature/grant.sql
sed -i "s/MYPGUSER/$user_pg/g" tmp/geonature/grant.sql
psql -h $db_host -U $user_pg -d $db_name -f tmp/geonature/grant.sql &>> $LOG_DIR/install_db.log

_verbose_echo "${green}Geonature - ${nocolor}Creating 'public' functions..."
psql -h $db_host -U $user_pg -d $db_name -f data/core/public.sql  &>> $LOG_DIR/install_db.log

# insert geonature data for usershub
psql -h $db_host -U $user_pg -d $db_name -f data/utilisateurs/adds_for_usershub.sql  &>> $LOG_DIR/install_db.log

_verbose_echo "${green}Geonature - ${nocolor}Download and extract habref file..."
if [ ! -d 'tmp/habref/' ]
then
    mkdir tmp/habref
fi
if [ ! -f 'tmp/habref/HABREF_50.zip' ]
then
    wget -q https://geonature.fr/data/inpn/habitats/HABREF_50.zip -P tmp/habref
else
    _verbose_echo "${green}Geonature - ${nocolor} HABREF_40.zip exists"
fi
unzip -q tmp/habref/HABREF_50.zip -d tmp/habref

wget -q https://raw.githubusercontent.com/PnX-SI/Habref-api-module/$habref_api_release/src/pypn_habref_api/data/habref.sql -P tmp/habref
wget -q https://raw.githubusercontent.com/PnX-SI/Habref-api-module/$habref_api_release/src/pypn_habref_api/data/data_inpn_habref.sql -P tmp/habref

# sed to replace /tmp/taxhub to ~/<geonature_dir>/tmp.taxhub
sed -i 's#'/tmp/habref'#'${GN_HOME}/tmp/habref'#g' tmp/habref/data_inpn_habref.sql

_verbose_echo "${green}Geonature - ${nocolor}Creating 'habitat' schema..."
psql -h $db_host -U $user_pg -d $db_name -f tmp/habref/habref.sql &>> $LOG_DIR/install_db.log

_verbose_echo "${green}Geonature - ${nocolor}Inserting INPN habitat data..."
psql -h $db_host -U $user_pg -d $db_name -f tmp/habref/data_inpn_habref.sql &>> $LOG_DIR/install_db.log

_verbose_echo "${green}Geonature - ${nocolor}Getting 'nomenclature' schema creation scripts..."
wget -q https://raw.githubusercontent.com/PnX-SI/Nomenclature-api-module/$nomenclature_release/data/nomenclatures.sql -P tmp/nomenclatures
wget -q https://raw.githubusercontent.com/PnX-SI/Nomenclature-api-module/$nomenclature_release/data/data_nomenclatures.sql -P tmp/nomenclatures
wget -q https://raw.githubusercontent.com/PnX-SI/Nomenclature-api-module/$nomenclature_release/data/nomenclatures_taxonomie.sql -P tmp/nomenclatures
wget -q https://raw.githubusercontent.com/PnX-SI/Nomenclature-api-module/$nomenclature_release/data/data_nomenclatures_taxonomie.sql -P tmp/nomenclatures

_verbose_echo "${green}Geonature - ${nocolor}Creating 'nomenclatures' schema"

psql -h $db_host -U $user_pg -d $db_name -f tmp/nomenclatures/nomenclatures.sql  &>> $LOG_DIR/install_db.log
psql -h $db_host -U $user_pg -d $db_name -f tmp/nomenclatures/nomenclatures_taxonomie.sql  &>> $LOG_DIR/install_db.log

_verbose_echo "${green}Geonature - ${nocolor}Inserting 'nomenclatures' data..."

sed -i "s/MYDEFAULTLANGUAGE/$default_language/g" tmp/nomenclatures/data_nomenclatures.sql
psql -h $db_host -U $user_pg -d $db_name -f tmp/nomenclatures/data_nomenclatures.sql  &>> $LOG_DIR/install_db.log
psql -h $db_host -U $user_pg -d $db_name -f tmp/nomenclatures/data_nomenclatures_taxonomie.sql  &>> $LOG_DIR/install_db.log

_verbose_echo "${green}Geonature - ${nocolor}Creating 'commons' schema..."
cp data/core/commons.sql tmp/geonature/commons.sql
sed -i "s/MYLOCALSRID/$srid_local/g" tmp/geonature/commons.sql
psql -h $db_host -U $user_pg -d $db_name -f tmp/geonature/commons.sql  &>> $LOG_DIR/install_db.log

_verbose_echo "${green}Geonature - ${nocolor}Creating 'meta' schema..."
psql -h $db_host -U $user_pg -d $db_name -f data/core/meta.sql  &>> $LOG_DIR/install_db.log

_verbose_echo "${green}Geonature - ${nocolor}Creating 'ref_geo' schema..."
cp data/core/ref_geo.sql tmp/geonature/ref_geo.sql
sed -i "s/MYLOCALSRID/$srid_local/g" tmp/geonature/ref_geo.sql
psql -h $db_host -U $user_pg -d $db_name -f tmp/geonature/ref_geo.sql  &>> $LOG_DIR/install_db.log

if [ "$install_sig_layers" = true ];
then
    _verbose_echo "${green}Geonature - ${nocolor}Insert default French municipalities (IGN admin-express)"
    if [ ! -f 'tmp/geonature/communes_fr_admin_express_2020-02.zip' ]
    then
        wget -q http://geonature.fr/data/ign/communes_fr_admin_express_2020-02.zip -P tmp/geonature
    else
        _verbose_echo "${green}Geonature - ${nocolor}tmp/geonature/communes_fr_admin_express_2020-02.zip already exist"
    fi
    unzip -q tmp/geonature/communes_fr_admin_express_2020-02.zip -d tmp/geonature

    # L'utilisateur geonatadmin n'existe pas et entraine une erreur (non bloquante) inutile.
    sed -i "s/geonatadmin/$user_pg/g" tmp/geonature/fr_municipalities.sql
    psql -h $db_host -U $user_pg -d $db_name -f tmp/geonature/fr_municipalities.sql &>> $LOG_DIR/install_db.log

    _verbose_echo "${green}Geonature - ${nocolor}Restore $user_pg owner"
    psql -h $db_host -U $user_pg -d $db_name -c "ALTER TABLE ref_geo.temp_fr_municipalities OWNER TO $user_pg;" &>> $LOG_DIR/install_db.log
    _verbose_echo "${green}Geonature - ${nocolor}Insert data in l_areas and li_municipalities tables"
    psql -h $db_host -U $user_pg -d $db_name -f data/core/ref_geo_municipalities.sql  &>> $LOG_DIR/install_db.log
    _verbose_echo "${green}Geonature - ${nocolor}Drop french municipalities temp table"
    psql -h $db_host -U $user_pg -d $db_name -c "DROP TABLE ref_geo.temp_fr_municipalities;" &>> $LOG_DIR/install_db.log

    _verbose_echo "${green}Geonature - ${nocolor}Insert departements"
    if [ ! -f 'tmp/geonature/departement_admin_express_2020-02.zip' ]
    then
        wget  -q http://geonature.fr/data/ign/departement_admin_express_2020-02.zip -P tmp/geonature
    else
        _verbose_echo "${green}Geonature - ${nocolor}tmp/geonature/departement_admin_express_2020-02.zip already exist"
    fi
    unzip tmp/geonature/departement_admin_express_2020-02.zip -d tmp/geonature

    sed -i "s/geonatadmin/$user_pg/g" tmp/geonature/fr_departements.sql
    psql -h $db_host -U $user_pg -d $db_name -f tmp/geonature/fr_departements.sql &>> $LOG_DIR/install_db.log

    _verbose_echo "${green}Geonature - ${nocolor}Restore $user_pg owner"
    psql -h $db_host -U $user_pg -d $db_name -c "ALTER TABLE ref_geo.temp_fr_departements  OWNER TO $user_pg;" &>> $LOG_DIR/install_db.log
    _verbose_echo "${green}Geonature - ${nocolor}Insert data in l_areas table"
    psql -h $db_host -U $user_pg -d $db_name -f data/core/ref_geo_departements.sql  &>> $LOG_DIR/install_db.log
    _verbose_echo "${green}Geonature - ${nocolor}Drop french departements temp table"
    psql -h $db_host -U $user_pg -d $db_name -c "DROP TABLE ref_geo.temp_fr_departements;" &>> $LOG_DIR/install_db.log
fi

if [ "$install_grid_layer" = true ];
then
    _verbose_echo "${green}Geonature - ${nocolor}Insert INPN grids"
    if [ ! -f 'tmp/geonature/inpn_grids.zip' ]
    then
        wget -q https://geonature.fr/data/inpn/layers/2020/inpn_grids.zip -P tmp/geonature
    else
        _verbose_echo "${green}Geonature - ${nocolor}tmp/geonature/inpn_grids.zip already exist"
    fi
    unzip -q tmp/geonature/inpn_grids.zip -d tmp/geonature
    sed -i 's#^COPY#\\COPY#g' tmp/geonature/inpn_grids.sql
    _verbose_echo "${green}Geonature - ${nocolor}Insert grid layers... (This may take a few minutes)"
    psql -h $db_host -U $user_pg -d $db_name -f tmp/geonature/inpn_grids.sql &>> $LOG_DIR/install_db.log
    _verbose_echo "${green}Geonature - ${nocolor}Restore $user_pg owner"
    psql -h $db_host -U $user_pg -d $db_name -c "ALTER TABLE ref_geo.temp_grids_1 OWNER TO $user_pg;" &>> $LOG_DIR/install_db.log
    psql -h $db_host -U $user_pg -d $db_name -c "ALTER TABLE ref_geo.temp_grids_5 OWNER TO $user_pg;" &>> $LOG_DIR/install_db.log
    psql -h $db_host -U $user_pg -d $db_name -c "ALTER TABLE ref_geo.temp_grids_10 OWNER TO $user_pg;" &>> $LOG_DIR/install_db.log
    _verbose_echo "${green}Geonature - ${nocolor}Insert data in l_areas and li_grids tables"
    psql -h $db_host -U $user_pg -d $db_name -f data/core/ref_geo_grids.sql  &>> $LOG_DIR/install_db.log
fi

if  [ "$install_default_dem" = true ];
then
    _verbose_echo "${green}Geonature - ${nocolor}Insert default French DEM (IGN 250m BD alti)"
    
    ### Ne fonctionne pas sur notre image docker ==> Solution de rechange...
    # if [ ! -f 'tmp/geonature/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip' ]
    # then
    #     wget -q http://geonature.fr/data/ign/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -P tmp/geonature
    # else
    #     echo "tmp/geonature/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip already exist"
    # fi
    # unzip -q tmp/geonature/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -d tmp/geonature
    # #gdalwarp -t_srs EPSG:$srid_local tmp/geonature/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc tmp/geonature/dem.tif &>> $LOG_DIR/install_db.log
    # raster2pgsql -s $srid_local -c -C -I -M -d -t 5x5 tmp/geonature/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc ref_geo.dem|psql -h $db_host -U $user_pg -d $db_name &>> $LOG_DIR/install_db.log
    ### Solution de rechange... on génère le sql ailleurs et on l'importe ici...
    unzip -q install/raster.zip
    psql -h $db_host -U $user_pg -d $db_name -f raster.sql  &>> $LOG_DIR/install_db.log
    rm -f raster.sql install/raster.zip
    
    #echo "Refresh DEM spatial index. This may take a few minutes..."
    psql -h $db_host -U $user_pg -d $db_name -c "REINDEX INDEX ref_geo.dem_st_convexhull_idx;" &>> $LOG_DIR/install_db.log
    if [ "$vectorise_dem" = true ];
    then
        _verbose_echo "${green}Geonature - ${nocolor}Vectorisation of DEM raster. This may take a few minutes..."
        psql -h $db_host -U $user_pg -d $db_name -c "INSERT INTO ref_geo.dem_vector (geom, val) SELECT (ST_DumpAsPolygons(rast)).* FROM ref_geo.dem;" &>> $LOG_DIR/install_db.log

        _verbose_echo "${green}Geonature - ${nocolor}Refresh DEM vector spatial index. This may take a few minutes..."
        psql -h $db_host -U $user_pg -d $db_name -c "REINDEX INDEX ref_geo.index_dem_vector_geom;" &>> $LOG_DIR/install_db.log
    fi
fi

_verbose_echo "${green}Geonature - ${nocolor}Creating 'imports' schema..."
psql -h $db_host -U $user_pg -d $db_name -f data/core/imports.sql  &>> $LOG_DIR/install_db.log

_verbose_echo "${green}Geonature - ${nocolor}Creating 'synthese' schema..."
cp data/core/synthese.sql tmp/geonature/synthese.sql
sed -i "s/MYLOCALSRID/$srid_local/g" tmp/geonature/synthese.sql
psql -h $db_host -U $user_pg -d $db_name -f tmp/geonature/synthese.sql  &>> $LOG_DIR/install_db.log
psql -h $db_host -U $user_pg -d $db_name -f data/core/synthese_default_values.sql  &>> $LOG_DIR/install_db.log

_verbose_echo "${green}Geonature - ${nocolor}Creating commons view depending of synthese"
psql -h $db_host -U $user_pg -d $db_name -f data/core/commons_synthese.sql  &>> $LOG_DIR/install_db.log

_verbose_echo "${green}Geonature - ${nocolor}Creating 'exports' schema..."
psql -h $db_host -U $user_pg -d $db_name -f data/core/exports.sql  &>> $LOG_DIR/install_db.log

_verbose_echo "${green}Geonature - ${nocolor}Creating 'monitoring' schema..."
psql -h $db_host -U $user_pg -d $db_name -v MYLOCALSRID=$srid_local -f data/core/monitoring.sql  &>> $LOG_DIR/install_db.log

_verbose_echo "${green}Geonature - ${nocolor}Creating 'permissions' schema"
psql -h $db_host -U $user_pg -d $db_name -f data/core/permissions.sql  &>> $LOG_DIR/install_db.log

_verbose_echo "${green}Geonature - ${nocolor}Insert 'permissions' data"
psql -h $db_host -U $user_pg -d $db_name -f data/core/permissions_data.sql  &>> $LOG_DIR/install_db.log

psql -h $db_host -U $user_pg -d $db_name -f data/core/sensitivity.sql  &>> $LOG_DIR/install_db.log

_verbose_echo "${green}Geonature - ${nocolor}Insert 'gn_sensitivity' data"
if [ ! -f 'tmp/geonature/referentiel_donnees_sensibles_v13.csv' ]
    then
        wget -q https://geonature.fr/data/inpn/sensitivity/referentiel_donnees_sensibles_v13.csv -P tmp/geonature
        mv tmp/geonature/referentiel_donnees_sensibles_v13.csv tmp/geonature/referentiel_donnees_sensibles.csv
    else
        _verbose_echo "${green}Geonature - ${nocolor}tmp/geonature/referentiel_donnees_sensibles_v13.csv already exist"
fi
cp data/core/sensitivity_data.sql tmp/geonature/sensitivity_data.sql
sed -i 's#'/tmp/geonature'#'${GN_HOME}/tmp/geonature'#g' tmp/geonature/sensitivity_data.sql
_verbose_echo "${green}Geonature - ${nocolor}Insert 'gn_sensitivity' data... (This may take a few minutes)"
psql -h $db_host -U $user_pg -d $db_name -f tmp/geonature/sensitivity_data.sql &>> $LOG_DIR/install_db.log

#Installation des données exemples
if [ "$add_sample_data" = true ];
then
    _verbose_echo "${green}Geonature - ${nocolor}Inserting sample datasets..."
    psql -h $db_host -U $user_pg -d $db_name -f data/core/meta_data.sql  &>> $LOG_DIR/install_db.log
fi

# if [ "$install_default_dem" = true ];
# then
#     rm tmp/geonature/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc
#     rm tmp/geonature/IGNF_BDALTIr_2-0_ASC_250M_LAMB93_IGN69_FRANCE.html
# fi

# # Suppression des fichiers : on ne conserve que les fichiers compressés
# echo "Cleaning files..."
# find ${GN_HOME}/tmp ! -name "*.zip" -exec rm -f {} +

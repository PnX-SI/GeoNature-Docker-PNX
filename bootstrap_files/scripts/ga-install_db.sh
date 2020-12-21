#!/bin/bash

. /usr/local/utils.lib.sh

verbose=1
mkdir -p ${GA_HOME}/tmp/atlas

#include user config = settings.ini
. ${GA_HOME}/atlas/configuration/settings.ini

LOG_DIR=${GA_HOME}/var/log

export PGPASSWORD=$user_pg_pass

cd ${GA_HOME}

_verbose_echo "${green}GeoNature-Atlas - ${nocolor}Création du schéma atlas..."
psql -h $db_host -U $user_pg -d $db_name -c "CREATE SCHEMA atlas;" &>> $LOG_DIR/install_db.log
_verbose_echo "${green}GeoNature-Atlas - ${nocolor}Création du schéma synthese..."
psql -h $db_host -U $user_pg -d $db_name -c "CREATE SCHEMA synthese;" &>> $LOG_DIR/install_db.log

_verbose_echo "${green}GeoNature-Atlas - ${nocolor}Création de vues de remplacement du FDW dans synthese..."
psql -h $db_host -U $user_pg -d $db_name -c "CREATE VIEW synthese.t_nomenclatures AS SELECT * FROM ref_nomenclatures.t_nomenclatures;" &>> $LOG_DIR/install_db.log
psql -h $db_host -U $user_pg -d $db_name -c "CREATE VIEW synthese.bib_nomenclatures_types AS SELECT * FROM ref_nomenclatures.bib_nomenclatures_types;" &>> $LOG_DIR/install_db.log
psql -h $db_host -U $user_pg -d $db_name -c "CREATE VIEW synthese.synthese AS SELECT * FROM gn_synthese.synthese;" &>> $LOG_DIR/install_db.log
psql -h $db_host -U $user_pg -d $db_name -c "CREATE VIEW synthese.cor_area_synthese AS SELECT * FROM gn_synthese.cor_area_synthese;" &>> $LOG_DIR/install_db.log

_verbose_echo "${green}GeoNature-Atlas - ${nocolor}Creation des table géographiques à partir du schéma ref_geo de la base geonature"
psql -h $db_host -U $user_pg -d $db_name -v type_maille=$type_maille -v type_territoire=$type_territoire -f data/gn2/atlas_ref_geo.sql &>> $LOG_DIR/install_db.log

# Conversion des limites du territoire en json (de la génération de fichier pour ??? dans l'install de la base???)

_verbose_echo "${green}GeoNature-Atlas - ${nocolor}Création de la structure de la BDD..."
psql -h $db_host -U $user_pg -d $db_name -f data/gn2/atlas_synthese.sql &>> $LOG_DIR/install_db.log

_verbose_echo "${green}GeoNature-Atlas - ${nocolor}Création des vues materialisées"
cp data/atlas.sql tmp/atlas/atlas.sql
sed -i "s/WHERE id_attribut IN (100, 101, 102, 103);$/WHERE id_attribut IN (${attr_desc}, ${attr_commentaire}, ${attr_milieu}, ${attr_chorologie});/g" tmp/atlas/atlas.sql
sed -i "s/date - 15$/date - $time/g" tmp/atlas/atlas.sql
sed -i "s/date + 15$/date - $time/g" tmp/atlas/atlas.sql

_verbose_echo "${green}GeoNature-Atlas - ${nocolor}Customisation de l'altitude"
insert=""
for i in "${!altitudes[@]}"
do
  if [ $i -gt 0 ];
  then
    let max=${altitudes[$i]}-1
    sql="INSERT INTO atlas.bib_altitudes VALUES ($i,${altitudes[$i-1]},$max);"
    insert="${insert}\n${sql}"
    fi
done
sed -i "s/INSERT_ALTITUDE/${insert}/g" tmp/atlas/atlas.sql
psql -h $db_host -U $user_pg -d $db_name -f tmp/atlas/atlas.sql &>> $LOG_DIR/install_db.log

_verbose_echo "${green}GeoNature-Atlas - ${nocolor}Création de la VM des observations de chaque taxon par mailles..."
psql -h $db_host -U $user_pg -d $db_name -f data/observations_mailles.sql &>> $LOG_DIR/install_db.log

# TODO: Read only user

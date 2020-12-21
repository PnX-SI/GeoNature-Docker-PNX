#!/bin/bash

. /usr/local/utils.lib.sh

verbose=1
mkdir -p ${TH_HOME}/{tmp/taxhub,var/log/installdb}

#include user config = settings.ini
. ${TH_HOME}/settings.ini

LOG_DIR=${TH_HOME}/var/log

export PGPASSWORD=$user_pg_pass

cd ${TH_HOME}

_verbose_echo "${green}Taxhub - ${nocolor}Création de la structure de la base..."
psql -h $db_host -U $user_pg -d $db_name -f data/taxhubdb.sql  &> $LOG_DIR/installdb/install_db.log

_verbose_echo "${green}Taxhub - ${nocolor}Décompression des fichiers du taxref..."

array=( TAXREF_INPN_v13.zip ESPECES_REGLEMENTEES_v11.zip LR_FRANCE_20160000.zip BDC_STATUTS_13.zip )
for i in "${array[@]}"
do
    if [ ! -f '${TH_HOME}/tmp/taxhub/'$i ]
    then
            wget -q http://geonature.fr/data/inpn/taxonomie/$i -P ${TH_HOME}/tmp/taxhub
            unzip -q ${TH_HOME}/tmp/taxhub/$i -d ${TH_HOME}/tmp/taxhub
    else
        _verbose_echo $i exists
    fi
done

_verbose_echo "${green}Taxhub - ${nocolor}Insertion  des données taxonomiques de l'inpn... (cette opération peut être longue)"
cd ${TH_HOME}
sed -i "s#/tmp#${TH_HOME}/tmp#g" data/inpn/data_inpn_taxhub.sql
psql -h $db_host -U $user_pg -d $db_name -f data/inpn/data_inpn_taxhub.sql &>> $LOG_DIR/installdb/install_db.log

_verbose_echo "${green}Taxhub - ${nocolor}Création de la vue représentant la hierarchie taxonomique..."
psql -h $db_host -U $user_pg -d $db_name -f data/materialized_views.sql  &>> $LOG_DIR/installdb/install_db.log

_verbose_echo "${green}Taxhub - ${nocolor}Insertion de données de base"
psql -h $db_host -U $user_pg -d $db_name -f data/taxhubdata.sql  &>> $LOG_DIR/installdb/install_db.log

if $insert_geonatureatlas_data
then
    _verbose_echo "${green}Taxhub - ${nocolor}Insertion de données nécessaires à GeoNature-atlas"
    psql -h $db_host -U $user_pg -d $db_name -f data/taxhubdata_atlas.sql  &>> $LOG_DIR/installdb/install_db.log
fi

if $insert_attribut_example
then
    _verbose_echo "${green}Taxhub - ${nocolor}Insertion d'un exemple d'attribut"
    psql -h $db_host -U $user_pg -d $db_name -f data/taxhubdata_example.sql  &>> $LOG_DIR/installdb/install_db.log
fi

if $insert_taxons_example
then
    _verbose_echo "${green}Taxhub - ${nocolor}Insertion de 8 taxons exemple"
    psql -h $db_host -U $user_pg -d $db_name -f data/taxhubdata_taxons_example.sql  &>> $LOG_DIR/installdb/install_db.log
fi

if $insert_geonaturev1_data
then
    _verbose_echo "${green}Taxhub - ${nocolor}Insertion de données nécessaires à GeoNature V1"
    psql -h $db_host -U $user_pg -d $db_name -f data/taxhubdata_geonaturev1.sql  &>> $LOG_DIR/installdb/install_db.log
fi

if $insert_geonaturev1_data && $insert_taxons_example
then
    _verbose_echo "${green}Taxhub - ${nocolor}Insertion des 8 taxons exemple aux listes nécessaires à GeoNature V1"
    psql -h $db_host -U $user_pg -d $db_name -f data/taxhubdata_taxons_example_geonaturev1.sql  &>> $LOG_DIR/installdb/install_db.log
fi

_verbose_echo "${green}Taxhub - ${nocolor}Modification du schema 'utilisateurs'"
psql -h $db_host -U $user_pg -d $db_name -f data/adds_for_usershub.sql &>> $LOG_DIR/installdb/install_db.log
psql -h $db_host -U $user_pg -d $db_name -f data/adds_for_usershub_views.sql &>> $LOG_DIR/installdb/install_db.log

# MAJ Docker

## Restauration BDD

### Récupération et traitement fichier backup
```


```

### Récupération des fichiers de migration des modules
do
```
wget https://raw.githubusercontent.com/PnX-SI/gn_module_import/1.2.0/data/migration/1.1.8to1.2.0.sql -O ${project_path}/data/services/postgres/backup/up_gn_module_import.sql
wget https://raw.githubusercontent.com/PnX-SI/gn_module_export/master/data/migrations/1.2.8to1.3.0.sql -O ${project_path}/data/services/postgres/backup/up_gn_module_export.sql
```

### Dans docker postgres

```
docker compose up -d postgres
docker compose exec postgres /bin/bash
```

#### Restauration du dump
```
gunzip /backup/geonature_backup.gz
psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -h localhost -f /backup/geonature_backup
```

##### Erreur index ?????? (pourquoi ???????)

```
psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -h localhost -c "CREATE INDEX trgm_idx ON atlas.vm_search_taxon USING gist (search_name gist_trgm_ops);"

psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -h localhost -c "CREATE INDEX i_tri_vm_taxref_list_forautocomplete_search_name ON taxonomie.vm_taxref_list_forautocomplete USING gist (search_name gist_trgm_ops);" #         long
```

#### MAJ à la main des modules

##### Pre-traitement PAG
```
psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -h localhost -c "DROP VIEW IF EXISTS gn_exports.v_synthese_sinp_dee"
```

##### Commandes

```
psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -h localhost -f /backup/up_gn_module_import.sql  -v ON_ERROR_STOP=1

psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -h localhost -f /backup/up_gn_module_export.sql  -v ON_ERROR_STOP=1
```


#### Geonature

```
docker compose up -d geonature-backend
docker compose exec geonature-backend /bin/bash
```

#### Pretraitement

##### PYR

```
geonature db upgrade taxonomie@4a549132d156 # 
geonature db stamp 1b1a3f5cd107 #
```

##### CAL

```
geonature db exec "delete from public.alembic_version where version_num in ('f61f95136ec3', 'aa7533601e41', '8222017dc3f6', 'cce08a64eb4f', )"
geonature db exec 'drop table gn_import_archives.these_30' # calanques
geonature db exec 'DROP SCHEMA gn_exports_save CASCADE'
```

##### PC

```
```

##### autoupgrade

```
geonature db autoupgrade
```

##### Stamping

```
geonature db stamp 2628978e1016 # dashboard
geonature db stamp c2d02e345a06 # export
geonature db stamp 4b137deaf201 # import
geonature db stamp 362cf9d504ec # monitoring
```

#### PATCH

##### PAG

```
geonature db exec 'DROP SCHEMA gn_exports_save CASCADE'
geonature db exec 'DROP TABLE gn_import_archives.pour_import_7'
```

##### CAL


##### GUA
geona
```
geonature db exec "delete from public.alembic_version where version_num in ('cce08a64eb4f')" # occtax sample
```

#### Autoupdate

```
geonature db autoupdate
```

#### modules (validation)

```
geonature db upgrade validation@head
```

#### stamps post

```
geonature db stamp a763fb554ff2 # nomenclatures_taxonomie_data
geonature db stamp 7dfd0a813f86 # ref_sensitivity_inpn
geonature db stamp 3fe8c07741be # taxhub admin
geonature db stamp 64d38dbe7739 # taxhub
geonature db stamp 6ec215fe023e # usershub
```
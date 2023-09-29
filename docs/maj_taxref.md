## MAJ taxref

### Préalable

créer le fichier des taxons manquants dans `data/services/postgres/backup/missing_taxons.csv`

```
<cd_nom> tab;<cd_nom de remplacement>
```
### Migration

Dans docker gn

```
geonature taxref migrate-to-v16 import-taxref-v16
geonature taxref migrate-to-v16 apply-changes --script_predetection /assets/taxref/taxref_migrate_preprocess.sql

# PAG
geonature taxref migrate-to-v16 apply-changes \
  --script_predetection ./2.1_taxref_changes_corrections_pre_detections_pag.sql \
  --script_postdetection ./2.2_taxref_changes_corrections_post_detections_pag.sql


```
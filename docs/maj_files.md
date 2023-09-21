### Geonature


#### Config toml GN

```
cp ${source_dir}/geonature/config/geonature_config.toml ${dest_dir}/geonature/config/geonature_config.toml
```

#### Config toml Modules
```
cp ${source_dir}/geonature/contrib/occtax/config/conf_gn_module.toml ${dest_dir}/geonature/config/occtax_config.toml
```

#### Config sous modules monitoring

```
# au cas par cas
cp -R ${source_dir}/geonature/contrib/gn_module_monitoring/contrib/* ${dest_dir}/geonature/media/monitorings/.
cur=$(pwd)
cd ${dest_dir}/geonature/media/monitorings/
for f in *; do
    echo $f
    test -d "$f" && mv "$f" "$( tr '[:lower:]' '[:upper:]' <<<"$f" )"
done
cd ${cur}

```

#### Mobile

```
cp -r ${source_dir}/geonature/backend/static/mobile/* ${dest_dir}/geonature/media/mobile/.
```

#### Medias

```
cp -r ${source_dir}/geonature/backend/static/medias/* ${dest_dir}/geonature/media/attachments/.

```

##### Customs

```
cp -r ${source_dir}/geonature/frontend/src/custom/images ${dest_dir}/geonature/custom/.
```

### Usershub

```
cp ${source_dir}/usershub/config/config.py ${dest_dir}/usershub/config/.
```

### Taxhub

#### Config

```
cp ${source_dir}/taxhub/apptax/config.py ${dest_dir}/taxhub/config/.
```

#### Medias
```
cp -r ${source_dir}/taxhub/static/medias/* ${dest_dir}/taxhub/media/.
```

### Atlas

#### Config
```
cp ${source_dir}/atlas/atlas/configuration/config.py ${dest_dir}/atlas/config
```

#### Custom

```
cp -r ${source_dir}/atlas/atlas/static/custom/* ${dest_dir}/atlas/custom
```
# GeoNature-Docker-PNX

Dépôt de gestion des scripts Docker de déploiement de GeoNature multi-instances des parcs nationaux.  
Il s'appuie sur les images Docker et docker-compose officiels de GeoNature (https://github.com/PnX-SI/GeoNature-Docker-services), mais y ajoutant les compléments spécifiques au déploiement des parcs nationaux (multi-instances, ajout de GeoNature-atlas, de pgAdmin, de scripts de sauvegarde...).

## Les services

 - `postgres`
 - `usershub`
 - `taxhub`
 - `geonature-backend`
 - `geonature-frontend`
 - `geonature-worker`: peut reprendre certaine tâches de geonature (import, export, mail, etc...)
 - `redis`

- `traefik`

```
SERVICE              PORTS
geonature-backend    8000/tcp
geonature-frontend   80/tcp
geonature-worker     8000/tcp
postgres             0.0.0.0:5435->5432/tcp, :::5435->5432/tcp
redis                6379/tcp
taxhub               5000/tcp
traefik              0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 0.0.0.0:8889->8080/tcp, :::80->80/tcp, :::443->443/tcp, :::8889->8080/tcp
usershub             5001/tcp
```


![Schéma des services](docs/schema_services_0.1.png)


## Utilisation

- rapatrier le dépôt
- se placer dans le répertoire du dépôt
- créer un fichier   `.env` (copier ou s'inspirer des fichiers `.env` exemples)
- créer les fichiers de configuration (vous pouver copier les fichiers de config *vide* d'un seul coup avec la commande `./scrits/init_applications_config.sh`)
- lancer les dockers avec la commande `docker compose up -d`
- les logs sont accessibles avec la commande `docker compose logs -f` ou `docker compose -f <nom du service>`

## Configuration

Il y a deux moyen pour configurer les applications: les fichiers de configuration et les variables d'environnement.

### Dossiers et fichiers

Par défaut, la structure des fichiers est la suivante

``` bash
./data
    - services/  # fichiers de config, custom, medias, backup, etc ... des application
                # destinés à être accessible et/ou modifiable par les utilisateur/administrateurs

        - geonature/
            - config/ # dossier de configuration contenant `geonature_config.toml`, `occtax_config.toml`, etc...
            - custom/ # dossier  `custom` de geonature (surcharge le dossier `static`)
            - media/ # dossier `media` de geonature
            - data/ # dossier `data` (peux contenir les fichiers pour les données des référentiels (taxref, ref_geo, ref_nomenclature, etc....))

        - usershub/
            - config/ # dossier contenant le fichier config.py

        - taxhub/
            - config/ # dossier contenant le fichier config.py
            - media/ # dossier des médias de taxhub

        - atlas
            - config/ # dossier contenant le fichier config.py
            - custom/ # dossier `custom de l'atlas (contient le style, les templates, les scripts js, etc...)

        - postgres
            - backup/ # contient les fichier de sauvegarde de la bdd

    - storage # stockage des dossiers nécessaire pour le fonctionnement
        - postgres # dossier contenant la bdd
        - pgadmin # ...
```

Voir la documentation des différentes applications pour renseigner les fichiers de configuration

- [fichier exemple pour GeoNature](./sources/GeoNature/config/geonature_config.toml.sample)
- [fichier exemple pour UsersHub](./sources/UsersHub/config/config.py.sample)
- [fichier exemple pour TaxHub](./sources/TaxHub/apptax/config.py.sample)
- [fichier exemple pour GeoNature-atlas](./sources/GeoNature-atlas/atlas/configuration/config.py.sample)

à noter que certaines variables seront fournies en tant que variables d'environnement (dans le fichier `.env` par exemple) (voir les fichiers [docker-compose](./docker-compose.yml))

comme par exemple:
  - `URL_APPLICATION`
  - `SQLALCHEMY_DATABASE_URI`
  - `SECRET_KEY`
### Variables d'environnement

Ces variable peuvent être définie dans un fichier `.env`.

#### Configuration des applications

Il est possible de passer par les variables d'environnemnt pour configurer les applications.

Par exemple toutes les variables préfixée par `GEONATURE_` seront traduite par un configuration de l'application GéoNature (`USERSHUB_` pour usershub, et `TAXHUB_` pour taxhub) (voir https://flask.palletsprojects.com/en/2.2.x/api/#flask.Config.from_prefixed_env).

Par exemple:
- `GEONATURE_SQLALCHEMY_DATABASE_URI` pour `app.config['SQLALCHEMY_DATABASE_URI']`
- `GEONATURE_CELERY__broker_url` pour `app.config['GEONATURE_CELERY']['broker_url]`

#### Configuration des services

Voir les fichiers d'exemple:

- [configuration de développement](./.env.dev.exemple)

- [configuration de production](./.env.prod.exemple)

##### Quelques variables essentielles

- `GDS_VERSION`: Version de GeoNature-Docker-services (donne la version des applications) (voir le fichier  [changelog](./docs/changelog.md) pour le détails des versions des applications)

- `DOMAIN`: nom de domaine des applications

- `PROJECT_NAME`: (gds) nom du projet, se repercute sur le nom des container et des réseaux, peut être utile dans le cas de plusieurs instances hébergées sur un même serveur

- `APPLICATIONS_PREFIX`: preffixe de l'url de l'application (s'il n'est pas à la racine du nom de domaine)

- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_HOST`, `POSTGRES_DB`, `POSTGRES_PORT`: paramètres  d'accès à la bdd

## Package et versionnement

Une actions permet la publication d'image dockers sur les packages du dépôt.

- `gds-geonature-backend:<VERSION>` (Geonature + 4 modules)
- `gds-geonature-frontend:<VERSION>` (Geonature + 4 modules)

La valeur de `VERSION` peut être:

- `current`: branche *travail en cours*
- `develop`: branche *develop* (un peu plus stable que current)
- `main`: correspond à la dernière release
- `1.1`: version releasée (voir le fichier [changelog](./docs/changelog.md) pour avoir le détails des applicaitons et des modules.


### Liens utiles
## Geonature

https://github.com/PnX-SI/GeoNature

- [`Dockerfile` backend](https://github.com/PnX-SI/GeoNature/blob/master/backend/Dockerfile)
- [`Dockerfile` frontend](https://github.com/PnX-SI/GeoNature/blob/master/frontend/Dockerfile)

- [`Dockerfile` backend + 4 modules](./build/Dockerfile-geonature-backend)
- [`Dockerfile` frontend + 4 modules](./build/Dockerfile-geonature-frontend)


## UsersHub

https://github.com/PnX-SI/UsersHub

- [`Dockerfile`](https://github.com/PnX-SI/UsersHub/blob/master/Dockerfile)


#### TaxHub

https://github.com/PnX-SI/Taxhub

- [`Dockerfile`](https://github.com/PnX-SI/TaxHub/blob/master/Dockerfile)



# GeoNature-Docker-PNX

Dépôt de gestion des scripts Docker de déploiement de GeoNature multi-instances des parcs nationaux.  
Il s'appuie sur les images Docker et docker-compose officiels de GeoNature (https://github.com/PnX-SI/GeoNature-Docker-services), mais en y ajoutant les compléments spécifiques au déploiement des parcs nationaux (multi-instances, ajout de GeoNature-atlas, de pgAdmin, de scripts de sauvegarde...).

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

## Utilisation

- Rapatrier le dépôt
- Se placer dans le répertoire du dépôt
- Créer un fichier `.env` (copier le fichier d'exemple - `cp .env.example .env`) et modifiez le (`nano .env`)
- Créer les fichiers de configuration (vous pouver copier les fichiers de config *vide* d'un seul coup avec la commande `./scrits/init_applications_config.sh .env`)
- Lancer les dockers avec la commande `docker compose up -d`
- Les logs sont accessibles avec la commande `docker compose logs -f` ou `docker compose -f <nom du service>`

## Configuration

Il y a 2 moyens pour configurer les applications : les fichiers de configuration et les variables d'environnement.

### Dossiers et fichiers

Par défaut, la structure des fichiers est la suivante :

``` bash
./data
    - services/  # fichiers de config, custom, medias, backup, etc ... des applications
                # destinés à être accessibles et/ou modifiables par les administrateurs

        - geonature/
            - config/ # dossier de configuration contenant `geonature_config.toml`, `occtax_config.toml`, etc...
            - custom/ # dossier  `custom` de geonature (surcharge le dossier `static`)
            - media/ # dossier `media` de geonature
            - data/ # dossier `data` (peut contenir les fichiers pour les données des référentiels (taxref, ref_geo, ref_nomenclature, etc....))

        - usershub/
            - config/ # dossier contenant le fichier config.py

        - taxhub/
            - config/ # dossier contenant le fichier config.py
            - media/ # dossier des médias de taxhub

        - atlas
            - config/ # dossier contenant le fichier config.py
            - custom/ # dossier `custom de l'atlas (contient le style, les templates, les scripts js, etc...)

        - postgres
            - backup/ # contient les fichiesr de sauvegarde de la bdd

    - storage # stockage des dossiers nécessaires pour le fonctionnement
        - postgres # dossier contenant la bdd
        - pgadmin # ...
```

Voir la documentation des différentes applications pour renseigner les fichiers de configuration

- [fichier exemple pour GeoNature](https://github.com/PnX-SI/GeoNature/tree/master/config/geonature_config.toml.sample)
- [fichier exemple pour UsersHub](https://github.com/PnX-SI/UsersHub/tree/master/config/config.py.sample)
- [fichier exemple pour TaxHub](https://github.com/PnX-SI/TaxHub/tree/master/apptax/config.py.sample)
- [fichier exemple pour GeoNature-atlas](https://github.com/PnX-SI/GeoNature-atlas/tree/master/atlas/configuration/config.py.sample)

A noter que certaines variables seront fournies en tant que variables d'environnement (dans le fichier `.env` par exemple) (voir les fichiers [docker-compose](./docker-compose.yml))

Comme par exemple :
  - `URL_APPLICATION`
  - `SQLALCHEMY_DATABASE_URI`
  - `SECRET_KEY`

### Variables d'environnement

Ces variable peuvent être définies dans un fichier `.env`.

#### Configuration des applications

Il est possible de passer par les variables d'environnement pour configurer les applications.

Par exemple toutes les variables préfixées par `GEONATURE_` seront traduites par une configuration de l'application GeoNature (`USERSHUB_` pour UsersHub, et `TAXHUB_` pour TaxHub) (voir https://flask.palletsprojects.com/en/2.2.x/api/#flask.Config.from_prefixed_env).

Par exemple :

- `GEONATURE_SQLALCHEMY_DATABASE_URI` pour `app.config['SQLALCHEMY_DATABASE_URI']`
- `GEONATURE_CELERY__broker_url` pour `app.config['GEONATURE_CELERY']['broker_url]`

#### Configuration des services

Voir le [fichier d'exemple](./.env.example)

##### Quelques variables essentielles

- `GDS_VERSION` : Version de GeoNature-Docker-PNX (donne la version des applications) (voir le fichier [changelog](./docs/changelog.md) pour le détail des versions des applications)
- `DOMAIN` : URL des applications
- `PROJECT_NAME` : (gds) nom du projet, se repercute sur le nom des containers et des réseaux, peut être utile dans le cas de plusieurs instances hébergées sur un même serveur
- `APPLICATIONS_PREFIX` : préfixe de l'URL de l'application (s'il n'est pas à la racine du nom de domaine)
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_HOST`, `POSTGRES_DB`, `POSTGRES_PORT` : paramètres d'accès à la BDD

### Liens utiles

#### GeoNature

https://github.com/PnX-SI/GeoNature

- [`Dockerfile` backend](https://github.com/PnX-SI/GeoNature/blob/master/backend/Dockerfile)
- [`Dockerfile` frontend](https://github.com/PnX-SI/GeoNature/blob/master/frontend/Dockerfile)

- [`Dockerfile` backend + 4 modules](./build/Dockerfile-geonature-backend)
- [`Dockerfile` frontend + 4 modules](./build/Dockerfile-geonature-frontend)


#### UsersHub

https://github.com/PnX-SI/UsersHub

- [`Dockerfile`](https://github.com/PnX-SI/UsersHub/blob/master/Dockerfile)


#### TaxHub

https://github.com/PnX-SI/Taxhub

- [`Dockerfile`](https://github.com/PnX-SI/TaxHub/blob/master/Dockerfile)

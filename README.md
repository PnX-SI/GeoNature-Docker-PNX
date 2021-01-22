# GeoNature-docker

Utilisation de Docker pour le déploiement de GeoNature.

## Contributeurs

Ce _portage_ de GeoNature sous Docker a été réalisé par le [BRGM](https://www.brgm.fr) dans le cadre de la convention BRGM/OFB.

## Projets liés

### Applications

* [PnX-SI](https://github.com/PnX-SI) / [UsersHub](https://github.com/PnX-SI/UsersHub)
* [PnX-SI](https://github.com/PnX-SI) / [TaxHub](https://github.com/PnX-SI/TaxHub)
* [PnX-SI](https://github.com/PnX-SI) / [GeoNature](https://github.com/PnX-SI/GeoNature)
* [PnX-SI](https://github.com/PnX-SI) / [GeoNature-atlas](https://github.com/PnX-SI/GeoNature-atlas)

### Autres composants

* [kartoza](https://github.com/kartoza) / [docker-postgis](https://github.com/kartoza/docker-postgis) : Base de données PostgreSQL + PostGIS
* [pgAdmin](https://hub.docker.com/r/dpage/pgadmin4/) : Application d'interfaçage avec la base de données
* [nginX](https://hub.docker.com/_/nginx/) : Reverse Proxy

## Architecture

```mermaid
  graph TD
    classDef label stroke-width:0;
    classDef node fill:white,stroke:black;
    nginx(nginX);
    pgadmin(PGAdmin);
    app(Geonature App);
    db(Geonature DB);
    nginx -- 80 --> pgadmin
    nginx -- "5000 (GeoNature)" --> app
    nginx -- "5001 (UsersHub)" --> app
    nginx -- "5002 (TaxHUb)" --> app
    nginx -- "8080 (Atlas)" --> app
    pgadmin -- 5432 --> db
    app -- 5432 --> db
```

## Installation

### Prérequis/Informations initiales

_Dans notre exemple nous utiliserons un certain nombre d'assertions._

* Le répertoire `/applications` est la base de notre environnement de travail.
* Le répertoire `/applications/projets` contiendra les différents GeoNatures.
* Le répertoire `/applications/geonature` contiendra le contenu du dépôt git de _GeoNature_.
* Le répertoire `/applications/administration` contiendra les différents outils d'administration.

#### Dépôt geonature

* Dans le dépôt git, la branche à utiliser est `main`.
* Dans le dépôt git, les sources sont dans le répertoire racine (celui où est situé ce `README.md`).

### Etapes d'installation

#### Cloner le dépôt _GeoNature-docker_ sur la machine

Dans cet exemple, le dossier système `/applications` est le dossier dédié aux applications Docker.

```bash
mkdir -p /applications

cd /applications

git clone https://github.com/PnX-SI/GeoNature-docker.git geonature

### Actuellement le bon contenu est dans la branche "main", il faut donc se mettre dessus (si vous venez de checkout, ce sera le cas directement).
cd geonature
git checkout main
```

#### Construire l'image GeoNature (facultatif)

_Cette étape est facultative si l'image peut-être récupérée d'un registre Docker ou bien si le CI/CD du projet est mis en place._

```bash
### Dans le répertoire _app__, il faut adapter le nom du tag
docker build --force-rm -t geonature:geonature-verified app/
```

#### Créer un répertoire pour le GeoNature que l'on veut déployer, par exemple en spécifiant votre domaine (remplacer `<mondomaine.org>` par le nom de votre choix).

```bash
mkdir -p /applications/projets/<mondomaine.org>
```

#### Copier l'environnement

```bash
cp /applications/geonature/env.sample /applications/projets/<mondomaine.org>/.env
cp /applications/geonature/docker-compose.yaml /applications/projets/<mondomaine.org>/
```

#### Editer l'environnement

```bash
vim /applications/projets/<mondomaine.org>/.env
```

_Exemple de configuration (dans cet exemple, une image déjà présente est utilisé, si vous avez construit l'image docker par vous même, indiquez ici son tag):_

```properties
POSTGRES_DB=geonature
POSTGRES_USER=geonature_user
POSTGRES_PASS=geonature
PGDATA_DIR=/applications/projets/geonature.brgm-rec.fr/pgdata
BOOTSTRAP_DIR=/applications/geonature/bootstrap_files
GEONATURE_COMMON_DIR=/applications/projets/geonature.brgm-rec.fr/geonature_common
GEONATURE_DOMAIN=geonature.brgm-rec.fr
GEONATURE_PROTOCOL=https
GEONATURE_IMAGE=geonature:geonature-verified
NGINX_CONF=/applications/geonature/nginx.conf
HTTP_PROXY=http://someproxy.loc.al:port
PGADMIN_DEFAULT_EMAIL=user@domain.geonature_com
PGADMIN_DEFAULT_PASSWORD=SuperSecret
```

#### Créer le réseau permettant de gérer le _reverse proxy_

```bash
docker network create rpx_net
```

#### Copier le répertoire _nginx-proxy_ où on veut gérer le proxy

```bash
mkdir -p /applications/administration

cp nginx-proxy /applications/administration/nginx-proxy

```

#### Installer le service nginx-proxy

_Vous pouvez aussi aller lire la documentation dans le répertoire nginx-proxy._

```bash
cp /applications/administration/nginx-proxy/nginx-proxy.service /etc/systemd/system
systemctl daemon-reload
systemctl enable nginx-proxy --now
```

#### Installer le service geonature

```bash
### Copie de l'Unit
cp /applications/geonature/geonature.service /etc/systemd/system/

### Edition de l'Unit (au moins deux parties à modifier ##Geonature##)
vim /etc/systemd/system/geonature.service

### Activation du service
systemctl daemon-reload
systemctl enable geonature --now
```

## Mise à jour de la configuration

### Changement d'URL de l'application

Si vous avez besoin de changer l'URL de l'application (changement de DNS, ou bien passage de http à https), il ne suffit pas de modifier le `.env` pour que celà fonctionne. En effet, les fichiers de configuration de l'application étant transformés pour le front et dans une moindre mesure pour la partie Python, il faut aussi modifier ces fichiers là.

#### Dans tous les cas

Modifiez le `.env` pour mettre à jour l'URL et le protocole. Ce fichier est quand même réutilisé pour créer les `settings.ini` des différentes applications.

#### Configuration UsersHub

Modifiez le fichier `geonature_common/usershub/config/config.py` en remplaçant la valeur de la variable `URL_APPLICATION`.

#### Configuration TaxHub

_Taxhub_ n'utilise que le fichier `settings.ini`.

#### Configuration GeoNature

Modifier le fichier `geonature_common/geonature/config/geonature_config.toml` en remplaçant les valeurs pour `URL_APPLICATION`, `API_ENDPOINT` et `API_TAXHUB`.

Ensuite, il faut lancer la mise à jour de la configuration à l'application.

```bash
docker ps
# On récupère le hash du container de geonature pour lancer un exec dessus
docker exec -it xxxx /bin/bash
# Les commande suivantes sont à exécuter dans le container
# On va dans le Frontend
cd /geonature/geonature/frontend
# On active npm (via nvm)
nvm install
nvm use
# On va dans le Backend
cd /geonature/geonature/backend
# On active le venv Python et on lance la commande de mise à jour de la configuration
source venv/bin/activate
geonature update_configuration
deactivate
# On peut ensuite sortir du container (via CTRL+D ou autre)
```

#### Configuration Atlas

_Atlas_ n'utilise que le fichier `settings.ini`.

### Charger un dump

#### Création de la base

La base doit être créée avant côté PGAdmin.

Il faut penser à ajouter les extensions _postgis_ et _postgis_raster_ **avant** de lancer la restauration.

#### Upload du dump

Le dump doit être placé sur le serveur.

* Copier le dump dans `/applications/projet/votreprojetgeonature/geonature_common/dbdump`

Il faut ensuite aller dans le container de _PGAdmin_ pour copier le dump dans le répertoire qui va bien (_A noter, il pourrait probablement être possible de monter un volume sur le répertoire qui va bien_).

* Se connecter au container `docker exec -it votreprojetgeonature_pgadmin_1_xxxxxxx /bin/sh`
* Déplacer le dump `cp /geonature/geonature_common/dbdump/votre.dump /var/lib/pgadmin/storage/user_domain.com/`

#### Lancement de la restauration

Dans PGAdmin, sur votre nouvelle base, choisissez l'option _Restore_, choisissez le fichier (attention à bien afficher tous les types de fichiers). Dans les _Restore options_, cochez les _Do not save_ _Owner_ et _Privilege_.

_Il peut y avoir quelques erreurs, vérifiez si elles sont graves ou non (les erreurs de création de comptes ne sont pas graves)._

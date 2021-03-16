- supervisor start and stop si maj ou install
- test maj 
- bug install db ???

joel

# Version de tout depuis settings.ini du depot geonature

- [x] point d'entrée version gn dans .env GEONATURE VERSION
- gn : settings.ini avec variable environnement pour les version UH TH etc...
  - recupération GN

*Risque de confusion entre version de GN et version du docker ?? main*

# Code depuis git 

- changer wget par git
- recupération 
- maj 

* erreur/message version ambigue (tag qui devient une branche ??)*

# Mise à jour

 - test version installée / version settings ?
 - git co 
 - pip install / 
 - MAJ BDD auto ?????
   - [x] script qui donne les fichiers de migration à jouer  

# Gestion BDD

- séparer applicatif et bdd
- installation en une fois
  - testé sans ref_geo (long) 
- que faire si bdd existe 
  - (en particuler pour les modules??) 
  - variable drop à false !!!!!
  - il doit manquer le ln -s seulement 

# Atlas (install en un seul schéma ???)

# process installation

- 1) version gn depuis env
- 2) recup dépot GN / checkout version
- 3) recup versions UH TH (ATLAS??) depuis settings.ini
- 4) recup dépot UH TH / checkout

  # Draft cmd
  idgn=$(docker ps | grep geonature | awk '{print $1}'); docker exec -it ${idgn} /bin/bash
cd ../../GeoNature-docker/; docker build -t geonature:main app/; cd ../projets/localhost; docker-compose up geonature
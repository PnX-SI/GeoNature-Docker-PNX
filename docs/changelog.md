- mis en place un seul point d'entrée pour la version des applications :
  - GEONATURE_VERSION
  - les version de Usershub et Taxhub sont déduites du fichier settings.ini.sample (dans launch_app.sh)

- gestion la récupération du code à un version voulue par git
  - fonction `get_depot_git` dans `utils.lib.sh`
    - utilise depth=1 pour ne pas tout récupérer (GeoNature est très lourd) 
    - clone le depot s'il n'existe pas ou bien le met à la bonne version

- reprise de l'installation depuis `install_db.sh` de GeoNature
  - modifié à grand coup de sed
    - surtout pour eviter les sudo -n -u postgres ..
  - **attention en l'état ne se lance que si**
    - **gn n'est pas installé**
    - **ET la base n'existe pas ou drop_db=true (danger)**   
    - **a clarifier avec le docker db**


- mettre le numéro de tag dans les fichier sysfile/<application_installed> ce qui permet de
  - récupérer la version installée
  - comparer avec la version du dépot (depuis le fichier VERSION)
  - mettre en place des actions :
    - pas de version installée, on lance l'installation de l'appli
    - version installee = version depot, on ne fait rien
    - version installee != version depot, on lance un mise à jour (applis et BDD)

- installation et mise à jour meme fichier pour toutes les appli `install_app.sh`

- gestion des mise à jour (le cas échéant)
  - mise à jour applicatif : 
    - pip install requirements
    - (GN) npm ci et rebuild du frontend (update_configuration)
  - mise à jour bdd :
    - liste des fichiers à jouer donné par la fonction `migration_db_list_files` du fichier `utils.lib.sh`
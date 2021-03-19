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

- installation des modules import export et monitoring
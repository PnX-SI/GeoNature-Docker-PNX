# Mise à jour frontend
- pourquoi nvm install?
  - à faire dans le dockerfile ??

# Que faire si BDD existe deja, pour installer les modules correctement


- *module deja renseigné dans t_modules*
- lien symbolique 
- installation requirements
- installation package.json

- soit faire une install complete à la bonne version & ensuite migrer la vrai base 
- soit ajouter un script à jouer après install_app pour geonature
  - test lien symbolique n'existe pas(pour external_module/occtax, etc...) et module dans gn_commons.t_modules
  - faire les actions listée ci dessus
  

- soit changer le code install_gn_module

# Code depuis git 

- **erreur/message version ambigue (tag qui devient une branche ??)**

# Atlas
  - install (doit être classique)
  - install db (tout mettre dans un seul schema `atlas`) ??

# Installer les modules depuis la config (depuis le .env)

# ?? Pouvoir choisr les applis et ne pas tout installer??
- ça a du sens d'avoir un fichier install db par appli
  - comment suivre les install.db des version ?
  - tester si schema existe (utilisateur / taxonomie)?? -> install_db 
- dans sysfile il faut des fichier par appli et par app/db ?
- dans .env APPLICATIONS="geonature usershub taxhub"
  - dependances ? (pas de GN sans UH et TH dans la base)
  - version en base pour la BDD?   


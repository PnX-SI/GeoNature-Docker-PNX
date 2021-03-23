# Database settings
SQLALCHEMY_DATABASE_URI = "postgresql://geonature:geonature@db:5432/geonature"
SQLALCHEMY_TRACK_MODIFICATIONS = False
URL_APPLICATION ='http://127.0.0.1/usershub'

# Liste d'URL depuis lesquels on accepte des requetes croisées
URLS_COR = ['http://localhost:5000']

SECRET_KEY = 'super secret key'

# ID of UsersHub application
ID_APP = 1

# Authentification crypting method (hash or md5)
PASS_METHOD = 'hash'

# Choose if you also want to fill MD5 passwords (lower security)
# Only useful if you have old application that use MD5 passwords
FILL_MD5_PASS = False

COOKIE_EXPIRATION = 3600
COOKIE_AUTORENEW = True

# SERVER
PORT = 5001
DEBUG = False

ACTIVATE_API = True
ACTIVATE_APP = True

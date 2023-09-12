#!/bin/bash

if [ "$1" == "" ]; then
  echo
  echo "Indiquer en paramètre le fichier .env à utiliser pour récupérer la variable TRAEFIK_NETWORK_NAME"
  echo 
  exit 1
fi

if [ ! -e $1 ]; then
  echo
  echo "Le fichier ($1) est introuvable !!!"
  echo
  exit 1
fi

source $1
echo 
echo "Nom du réseau : $TRAEFIK_NETWORK_NAME"
echo


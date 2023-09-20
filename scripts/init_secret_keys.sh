file_path=$1

APPS="GEONATURE ATLAS USERSHUB TAXHUB"

for app in $(echo $APPS); do 
  sed -i "s/${app}_SECRET_KEY=.*/${app}_SECRET_KEY=\"$(uuidgen)\"/" $file_path
  grep "${app}_SECRET_KEY=" $file_path
done
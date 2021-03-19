
get_depot_git geonature $(get_version geonature)
manage_assets geonature
. $script_home_dir/geonature/config/settings.ini

cd $script_home_dir/geonature/install

# gros bazar pour pimpoer install_db.sh 
# principalement pour enlever les "sudo -n -u postgres" 

# version   
cat $script_home_dir/geonature/config/settings.ini.sample | grep release > /$script_home_dir/geonature/config/release.ini
cat /$script_home_dir/geonature/config/release.ini
. /$script_home_dir/geonature/config/release.ini


echo "set -e;" > ./install_db_2.sh
if $DEBUG; then 
 echo 'set -x' >> ./install_db_2.sh
fi
echo "export PGPASSWORD=$user_pg_pass; 
psqla='psql -h ${db_host} -d ${db_name} -U ${user_pg} -p ${db_port}';
psqlg='psql -h ${db_host} -d postgres -U ${user_pg} -p ${db_port}'; 
" >> ./install_db_2.sh
cat ./install_db.sh >> ./install_db_2.sh
sed -i '/^check_superuser$/d' ./install_db_2.sh
sed -i '/postgresql.conf/d' ./install_db_2.sh
sed -i 's/if $drop_apps_db/echo $drop_apps_db; if $drop_apps_db/' ./install_db_2.sh
sed -i 's/sudo -n -u postgres -s createdb.*/${psqlg} -c "CREATE DATABASE ${db_name};"/' ./install_db_2.sh    
sed -i 's/sudo -u postgres -s dropdb.*/\
query="SELECT pg_terminate_backend(pg_stat_activity.pid)\
 FROM pg_stat_activity WHERE pg_stat_activity.datname = '\'${db_name}\''\
 AND pid <> pg_backend_pid() ;"; ${psqlg} -c "${query}"; ${psqlg} -c "DROP DATABASE ${db_name};";/' ./install_db_2.sh    
sed -i 's/sudo -n -u "postgres" -s dropdb.*/${psqlg} -c "DROP DATABASE ${db_name};"/' ./install_db_2.sh    
sed -i 's/sudo -n -u postgres -s psql -d "${db_name}"/${psqla}/' ./install_db_2.sh
sed -i 's/sudo -n -u postgres -s psql -d $db_name/${psqla}/' ./install_db_2.sh
sed -i 's/sudo -u postgres -s psql -d $db_name/${psqla}/' ./install_db_2.sh
sed -i 's/sudo -n -u "postgres" -s psql/${psqlg}/' ./install_db_2.sh
sed -i 's/sudo -u postgres -s -- psql/$psqlg/' ./install_db_2.sh
sed -i 's/unzip/unzip -n/' ./install_db_2.sh
sed -i '/sudo service postgresql restart/d' ./install_db_2.sh
chmod +x ./install_db_2.sh

. install_db_2.sh && set_version_installed db $(get_version geonature)

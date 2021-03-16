. ${GN_HOME}/config/settings.ini
cd $GN_HOME/install

# gros bazar pour pimpoer install_db.sh 
# principalement pour enlever les "sudo -n -u postgres" 
echo "
set -e;
export PGPASSWORD=$user_pg_pass; 
psqla='psql -h ${db_host} -d ${db_name} -U ${user_pg} -p ${db_port}';
psqlg='psql -h ${db_host} -d postgres -U ${user_pg} -p ${db_port}'; 
" > ./install_db_2.sh
cat ./install_db.sh >> ./install_db_2.sh
sed -i '/^check_superuser$/d' ./install_db_2.sh
sed -i '/postgresql.conf/d' ./install_db_2.sh
sed -i 's/sudo -n -u postgres -s createdb.*/${psqlg} -c "CREATE DATABASE ${db_name};"/' ./install_db_2.sh    
sed -i 's/sudo -n -u "postgres" -s dropdb.*/${psqlg} -c "DROP DATABASE ${db_name};"/' ./install_db_2.sh    
sed -i 's/sudo -n -u postgres -s psql -d "${db_name}"/${psqla}/' ./install_db_2.sh
sed -i 's/sudo -n -u postgres -s psql -d $db_name/${psqla}/' ./install_db_2.sh
sed -i 's/sudo -u postgres -s psql -d $db_name/${psqla}/' ./install_db_2.sh
sed -i 's/sudo -n -u "postgres" -s psql/${psqlg}/' ./install_db_2.sh
sed -i 's/sudo -u postgres -s -- psql/$psqlg/' ./install_db_2.sh
sed -i 's/unzip/unzip -n/' ./install_db_2.sh
sed -i '/sudo service postgresql restart/d' ./install_db_2.sh
chmod +x ./install_db_2.sh

# cat ./install_db_2.sh | grep sudo 
./install_db_2.sh

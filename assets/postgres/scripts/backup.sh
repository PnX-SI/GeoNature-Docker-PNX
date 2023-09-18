#!/bin/sh
#
# Crée un dump de la base geonature
# Renseigne le fichier log avec la date de backup
#   et la taille du fichier non compressé

echo "+-------------------------------+"
echo "| Database backup               |"
echo "+-------------------------------+"

# - 1 )logs (start)
log_file_global=/backup/backup.log

date_start=$(date '+%Y-%m-%d_%H-%M-%S')
date_jour=$(date '+%Y-%m-%d')
log_line_start="${date_start} -> ... (en cours)"
echo $log_line_start >> $log_file_global


# - 2 )creation du backup

backup_file=/backup/geonature_backup

export PGPASSWORD=${POSTGRES_PASS}
pg_dump --format=plain \
    --create \
    --no-owner --no-acl \
    -d ${POSTGRES_DB} -h localhost -U ${POSTGRES_USER} \
    > $backup_file

#   - compression du backup
tar cvfz ${backup_file}_${date_jour}.tar.gz ${backup_file}

#   - on regarde la taille du backup non compressé (pour les logs)
size_h_backup=$(ls -lh $backup_file | awk '{print $5}')
size_backup=$(ls -l $backup_file | awk '{print $5}')

#   - suppression du fichier non compressé
rm ${backup_file}

# - 3) log (end)
date_end=$(date '+%Y-%m-%d_%H-%M-%S')
log_line_end="${date_start} -> ${date_end} : $size_h_backup ($size_backup)"
sed -i "s/${log_line_start}.*/${log_line_end}/" $log_file_global
tail -n 1 $log_file_global

# rotation des fichiers
# on garde les 5 derniers dumps ?
files_to_remove=$(ls /backup/geonature_backup* | sort -r | awk 'NR > 5 { print $1}')

if [ ! -z "${files_to_remove}" ]; then
    echo rm ${files_to_remove}
    rm ${files_to_remove}
fi
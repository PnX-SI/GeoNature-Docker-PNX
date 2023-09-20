#!/bin/sh

# Met à jour la vue de l'atlas
# Et renseigne les logs sur la bonne execution de la tâche

echo "+--------------------------------------+"
echo "| atlas.refresh_materialized_view_data |"
echo "+--------------------------------------+"

date_start=$(date '+%Y-%m-%d_%H-%M-%S')

# - fichiers de logs
log_file_global=/backup/refresh_atlas.log

log_line_start="${date_start} -> ... (en cours)"
echo $log_line_start >> $log_file_global

#   - détails de l'action en cours
log_file_detail=/backup/refresh_atlas_${date_start}.log

# requete sql atlas.refresh_materialized_view_data();

export PGPASSWORD=${POSTGRES_PASS}
psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -h localhost -c "SELECT atlas.refresh_materialized_view_data();" > $log_file_detail 2>&1

if grep 'ERR' $log_file_detail; then
    echo fail
    result="fail"
else
    rm -f $log_file_detail
fi

# log de fin de l'action

date_end=$(date '+%Y-%m-%d_%H-%M-%S')
log_line_end="${date_start} -> ${date_end} ${result}"
sed -i "s/${log_line_start}.*/${log_line_end}/" $log_file_global

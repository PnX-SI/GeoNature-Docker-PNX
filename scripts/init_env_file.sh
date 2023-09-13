#!/bin/bash
# init_env_file.sh .env.example settings.ini .env

template_file=$1
settings_file=$2
output_file=$3

cp $template_file $output_file

for line in $(cat $settings_file); do
    # skip comment
    [[ $line =~ ^#.* ]] && continue
    var_name=${line%%=*}
    sed -i "s/${var_name}=.*/$line/" $output_file
done
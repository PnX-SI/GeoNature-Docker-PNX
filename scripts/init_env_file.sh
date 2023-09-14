#!/bin/bash
# init_env_file.sh .env.example settings.ini .env

set -e

template_file=$1
settings_file=$2
output_file=$3

sep="&" # separator for sed

cp $template_file $output_file

# https://stackoverflow.com/1521462/looping-through-the-content-of-a-file-in-bash
while IFS= read -r line || [ -n "$line" ]; do
    # skip comment
    [[ $line =~ ^#.* ]] && continue
    var_name=${line%%=*}
    [[ -z "$var_name" ]] && continue
    sed -i "s${sep}${var_name}=.*${sep}${line}${sep}" $output_file
    grep "^${var_name}=" ${output_file}
done < ${settings_file}

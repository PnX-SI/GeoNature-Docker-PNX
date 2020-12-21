#!/bin/bash

## This is meant to be used as a lib, nothing is actually executable in here

## a few usefull vars
## Colors
blue='\e[0;34m'
green='\e[0;32m'
orange='\e[0;33m'
red='\e[0;31m'
nocolor='\e[0m'

##  exit status codes
STATUS_OK=0
STATUS_WARN=1
STATUS_CRITICAL=2

## Verbose function
function _verbose
{
    if [[ $verbose -eq 1 ]]; then
        no_log=0
        if [[ -z $log_file ]]; then
            echo -e "${orange}Warning: log file undefined${nocolor}"
            exit $STATUS_WARN
        fi
        if [[ ! -f ${log_file} ]]; then
            mkdir -p $(dirname $log_file)
            touch $log_file
        fi
        if [[ ! -w ${log_file} ]]; then
            echo -e "${orange}Warning: cannot write to ${log_file}${nocolor}"
            no_log=1
        fi
        if [[ $no_log -eq 1 ]]; then
            _verbose_echo $1
        else

            echo -e $1 | tee -a $log_file
        fi
    fi
}
## verbose (echo only)
function _verbose_echo
{
    if [[ $verbose -eq 1 ]]; then
        echo -e $1
    fi
}

## double check that a tcp port is open to connection
function wait_for_restart
{
    service_connection=$1
    if [[ "x$1" = "x" ]]; then
        service_connection='localhost:22'
    fi
    timeout=$2
    if [[ "x$2" = "x" ]]; then
        timeout=300
    fi
    sleep_time=$3
    if [[ "x$3" = "x" ]]; then
        sleep_time=5s
    fi

    wait-for-it -t ${timeout} ${service_connection}
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    _verbose_echo "Waiting ${sleep_time} before checking again"
    sleep $sleep_time
    wait-for-it -t ${timeout} ${service_connection}
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
}

## Downloader function
function downloader
{
    ## finding destination directory create it if not found
    dest_dir="/data"
    if [[ ! -z $1 ]]; then
        dest_dir=$1
    fi
    mkdir -p $dest_dir
    ## overriding file list name if provided
    if [[ ! -z $2 && -f $2 ]]; then
        file_list=$2
    else
        file_list="${dest_dir}/download-list.txt"
    fi
    ## should we auto unzip zipped files
    auto_unzip=1
    if [[ ! -z $3 && $3 -eq 1 ]]; then
        auto_unzip=0
    fi

    if [[ ! -f $file_list ]]; then
        exit $STATUS_WARN
    fi

    ## looping on file list
    for item in $(cat ${file_list} | grep -v '^#'); do

        i=${item##*/}
        ## if item doesnot exists: download it
        if [ ! -f "${dest_dir}/$i" ]; then
            _verbose "Download $item to ${dest_dir}/$i"
            wget -q $item -P ${dest_dir}
        else
            _verbose "${dest_dir}/$i already exists"
        fi

        ## auto unzip if necessary and wanted
        if [[ $auto_unzip -eq 1 ]]; then
            filename=$(basename -- "$item")
            extension="${filename##*.}"
            filename="${filename%.*}"

            if [[ $extension = 'zip' && ! -f "${dest_dir}/$i.unzipped" ]]; then
                unzip -nq ${dest_dir}/$i -d ${dest_dir}
                touch "${dest_dir}/$i.unzipped"
            fi
        fi
    done
}

# Do we need the proxy
function enable_proxy
{
    if [[ ${USE_PROXY} -eq 1 ]]; then
        export http_proxy=${PROXY_ADDRESS}
        export https_proxy=${PROXY_ADDRESS}
        export HTTP_PROXY=${PROXY_ADDRESS}
        export HTTPS_PROXY=${PROXY_ADDRESS}
    fi
}

# wait for a file to be written
function wait_for_file
{
    file_to_wait=$1
    wait_message="Waiting for ${file_to_wait}"
    repeat_timer=30
    if [[ ! -z $2 ]]; then
        repeat_timer=$2
    fi
    if [[ ! -z $3 ]]; then
        wait_message=$3
    fi
    while [ ! -f $file_to_wait ]; do sleep $repeat_timer; echo "${wait_message}"; done
}

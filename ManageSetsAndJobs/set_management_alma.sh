#!/bin/bash

config="/sirsi/webserver/config/"
. ${config}environ     # dot in environ variables

# export all of the environ variables to my children
for env_var in $(cat ${config}environ | awk -F'=' '{print $1}')
do
  export ${env_var}
done

direc="/sirsi/webserver/external_data/set_management/barcodes/"
archive="/sirsi/webserver/external_data/set_management/barcodes/archive/"
workdir="/sirsi/webserver/external_data/set_management/barcodes/work/"
bindir="/sirsi/webserver/bin/"
configdir="/sirsi/webserver/config/"
setid1=$(${bindir}create_alma_set_api.py ${configdir}alma_create_delete_set.cfg)
setid2=$(${bindir}create_alma_set_api.py ${configdir}alma_create_process_set.cfg)
setfile="/tmp/setids"
mail_list="acoope5@emory.edu"

if [ -e ${direc}delete_me_* ]; then
    for f in ${direc}delete_me_*; do
        split -l 100 -d ${f} ${workdir}deletes_
        mv ${f} ${archive}
    done
fi

if [ -e ${direc}process_me_* ]; then
    for f in ${direc}process_me_*; do
        split -l 100 -d ${f} ${workdir}process_
        mv ${f} ${archive}
    done
fi

if [ -e ${workdir}deletes_00 ]; then
    for f in ${workdir}deletes*; do
        cat ${f} | ${bindir}addto_alma_set_api.py ${configdir}alma_add_members_api.cfg ${setid1} > "/tmp/addto_$$.log" 2> "/tmp/addto_$$.err"
        rm ${f}
    done
    number_of_members=$(echo ${setid1} | ${bindir}get_alma_set_api.py ${configdir}alma_get_set_api.cfg)
    if [ ${number_of_members} -lt 4500 ]; then
        mail -s "Delete Me File is Small" ${mail_list} <<EOM
        delete_me only has ${number_of_members} members.
EOM
    fi
fi

if [ -e ${workdir}process_00 ]; then
    for f in ${workdir}process*; do
        cat ${f} | ${bindir}addto_alma_set_api.py ${configdir}alma_add_members_api.cfg ${setid2} > "/tmp/addto_$$.log" 2> "/tmp/addto_$$.err"
        rm ${f}
    done
    number_of_members=$(echo ${setid2} | ${bindir}get_alma_set_api.py ${configdir}alma_get_set_api.cfg)
    if [ ${number_of_members} -lt 4500 ]; then
        mail -s "Process Me File is Small" ${mail_list} <<EOM
        process_me only has ${number_of_members} members.
EOM
    fi
fi

echo ${setid1} > ${setfile}

echo ${setid2} >> ${setfile}

exit 0

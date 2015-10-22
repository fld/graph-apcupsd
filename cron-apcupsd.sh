#!/bin/bash
apc_status="$(/sbin/apcaccess status | 
        grep -e ^LINEV -e ^LOADPCT -e ^OUTPUTV -e ^ITEMP -e ^BATTV -e ^NUMXFERS |
                awk '{ printf "%s:", $3}')"

[[ $1 == "-d" ]] && { echo "$apc_status"; exit 0; }

if [[ -z $apc_status ]]; then
        echo "$0: Error: empty \$apc_status" >2
        exit 1
fi

#echo "${apc_status:0:-1}" >> /etc/apcupsd/debug.log
rrdtool update /etc/apcupsd/apcupsd.rrd N:"${apc_status:0:-1}"

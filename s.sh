#!/usr/bin/env bash 
# ----------------------------------------------------------------------------- #
#         File: s.sh
#  Description: search yify database titles to find the rowid for given title
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-04-12 - 14:00
#      License: MIT
#  Last update: 2018-04-18 15:39
# ----------------------------------------------------------------------------- #
#  YFF Copyright (C) 2012-2018 j kepler
_DATABASE=yify.sqlite
_TABLE=yify
OPT_COLS="rowid,id,year,title"
PATTERN=$1
if [[ -z "$PATTERN" ]]; then
    echo -n "Enter pattern: "
    read PATTERN
fi
[[ -z "$PATTERN" ]] && exit 0
#echo $PATTERN

OPT_WHERE=" title LIKE '%"${PATTERN}"%' "
#echo $OPT_WHERE
RES=$( sqlite3 -separator $'\t'  -header -nullvalue 'NULL' $_DATABASE "SELECT ${OPT_COLS} FROM $_TABLE WHERE $OPT_WHERE ;" )
#echo "$OPT_COLS"
echo "$RES"

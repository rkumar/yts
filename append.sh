#!/usr/bin/env bash 
# ----------------------------------------------------------------------------- #
#         File: append.sh
#  Description: join the latest files uploaded by yify into our database
#          Is this being used at all ? I am directly updating our database from 
#           the json file. I don't use this at all.
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-04-05 - 18:24
#      License: MIT
#  Last update: 2018-04-21 10:15
# ----------------------------------------------------------------------------- #
#  YFF Copyright (C) 2012-2018 j kepler
#

if [[ ! -f "pending.txt" ]]; then
    echo "It appears there are no pending films to update"
    echo "File: pending.txt not found" 1<&2
    exit 1
fi
echo "backup.sh id.tsv before running this"
backup.sh id.tsv
echo
wc -l latest.txt id.tsv
# Unfortunately I am left with duplicate rows despite the sort, since the same row comes again
#  with a different rating or with genres added. So i have to manually delete the same.
cat latest.txt >> id.tsv
sort -u id.tsv | sponge id.tsv
sort -n -k1 id.tsv | sponge id.tsv
wc -l latest.txt id.tsv

echo "delete pending.txt now"

#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: yts.sh
# 
#         USAGE: ./yts.sh 
# 
#   DESCRIPTION: download files from yts in batches
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 04/03/2018 09:46
#      REVISION:  2018-04-21 20:37
#===============================================================================

#!/usr/bin/env bash
#  Last update: 2018-03-14 08:49

STARTPAGE=1
STARTPAGE=50
STARTPAGE=70
STARTPAGE=80
STARTPAGE=120
STARTPAGE=140
if [ $# -eq 0 ]
then
    echo "I got no filename" 1>&2
else
    echo "Got $*" 1>&2
    #echo "Got $1"
    STARTPAGE=$1
fi
echo "Starting at $STARTPAGE"
counter=$STARTPAGE
while [ $counter -lt 144 ]
do
    OUT=list_movies-$counter.json
    wget -O $OUT.gz https://yts.am/api/v2/list_movies.json\?limit\=50\&page\=$counter
    ls -l $OUT.gz
    gunzip $OUT.gz
    gron $OUT | fgrep 'title_long'
    gron $OUT | fgrep '.id' | tail -2

    ls -l $OUT
    sleep 15
    counter=$(( $counter + 1 ))
done

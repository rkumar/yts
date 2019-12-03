#!/usr/bin/env bash
#  Last update: 2019-10-20 09:29

## import from a file named list-movies.json.
## I am not logner able to connect via cronjob to yts.ag to get the listing. So i have to
## manually save the file and add the date. This will convert to the current date and run import.rb

# NOTE: when called from applescript the stat -c was giving error and so all the
# files in json dir have no date 2019-03-01 -
## use the date of the file, sometimes it is older
EFILE="list_movies.json"
if [[ -f ${EFILE} ]]; then
    #DATE=$(date +"%Y-%m-%d")
    DATE=$( /usr/local/opt/coreutils/libexec/gnubin/stat -c "%y" ${EFILE} | cut -c1-10 )
    if [[ -z "$DATE" ]]; then
        DATE=$(date +"%Y-%m-%d")
    fi
    FILE="list-movies-${DATE}.json"
    echo "Renaming $EFILE to $FILE"
    cp $EFILE $FILE
    date >> lastran.log
fi
# added -q on 2019-10-18 - so i don't get a popup when applescript executes
./import.rb --quiet
if [[ -f ${EFILE} ]]; then
    mv $EFILE $EFILE.old
fi

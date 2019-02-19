#!/usr/bin/env bash
#  Last update: 2019-02-19 12:25

## import from a file named list-movies.json.
## I am not logner able to connect via cronjob to yts.ag to get the listing. So i have to
## manually save the file and add the date. This will convert to the current date and run import.rb

## use the date of the file, sometimes it is older
EFILE="list_movies.json"
if [[ -f ${EFILE} ]]; then
    #DATE=$(date +"%Y-%m-%d")
    DATE=$( stat -c "%y" ${EFILE} | cut -c1-10 )
    FILE="list-movies-${DATE}.json"
    echo "Renaming $EFILE to $FILE"
    cp $EFILE $FILE
    date >> lastran.log
fi
./import.rb
if [[ -f ${EFILE} ]]; then
    mv $EFILE $EFILE.old
fi

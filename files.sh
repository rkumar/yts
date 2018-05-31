# ----------------------------------------------------------------------------- #
#         File: files.sh
#  Description: insert all json files into yify database, yify table
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-04-09 - 08:44
#      License: MIT
#  Last update: 2018-04-21 20:36
# ----------------------------------------------------------------------------- #
#  YFF Copyright (C) 2012-2018 j kepler
# This inserts all json files, so one usually clears the database before that.
echo "Writing all files into database"
echo "Please clear all data before continuing ..."
echo "Press ENTER to continue"
read
# maybe we should renumber the files padding with 0 so they can just sort properly themselves
# starting with 1 for oldest so we can keep adding
NEWONLY=
if [[ -z "$NEWONLY" ]]; then
ctr=145
while [[ $ctr -gt 1 ]]
do
    (( ctr = ctr - 1 ))
    echo $ctr
    file="./json/list_movies-$ctr.json"
    if [[ ! -f "$file" ]]; then
        echo "File: $file not found" 1<&2
    else
        ls -l $file
        ./import.rb $file
    fi
done
fi
echo "-------------------"
echo "CURRENT DAILY FILES"
echo "-------------------"

for f in ./json/list-movies-*.json
do
    ls -l $f
    ./import.rb $f
done
echo "Count:"
sqlite3 yify.sqlite "select count(*) from yify"
echo "Max Id:"
sqlite3 yify.sqlite "select max(id) from yify"

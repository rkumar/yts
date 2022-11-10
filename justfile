# https://github.com/casey/just
# run import program on list_movies.json
# After this Insert new movies into imdb database using sync.
# TODO :Add imdbrating field to yify, and update it after sync
default:
	#!/usr/bin/env bash
	  if [[ -f "list_movies.json" ]]; then
	    ./imp.sh
	  fi
	  just sync
	  # update titles list only if sqlite file is newer than titles.list
	  if [[ yify.sqlite -nt ~/imdbdata/src/titles.list ]]; then
	  	title.sh --refresh
	  fi


# download imdb data for new entries and insert into imdb database
# f.sh returns an exit status of 1 if file exists.
# Run this after running the default
# Use last_sync id in first query and sort on rating desc.
sync:
  #!/usr/bin/env bash
  LAST_ID=$(tail -1 last_sync.txt)
    sqlite3 yify.sqlite "SELECT imdbid, genres FROM yify WHERE rowid > $LAST_ID ORDER BY rating DESC LIMIT 200" | grep -v 'Horror' | cut -f1 -d '|' | tr '\n' ' ' | xargs ~/bin/src/f.sh
    sqlite3 yify.sqlite "SELECT max(rowid)    FROM yify " >> last_sync.txt

syncorig:
    @sqlite3 yify.sqlite "SELECT imdbid, genres FROM yify ORDER BY rowid DESC LIMIT 200" | grep -v 'Horror' | cut -f1 -d '|' | tr '\n' ' ' | xargs ~/bin/src/f.sh
    @sqlite3 yify.sqlite "SELECT max(rowid)    FROM yify " >> last_sync.txt

synctest:
    @sqlite3 yify.sqlite "SELECT imdbid, genres FROM yify ORDER BY rowid DESC LIMIT 200" | grep -v 'Horror' | cut -f1 -d '|' | tr '\n' ' '

# Generate database of yify titles that have not been inserted into imdb database
missing:
  ./attachimdbttcode.sh

# update imdbrating in yify from imdb.sqlite
updaterating:
  ./attach_update-imdbRating.sh

# search torrents for matching title, output to pager/most
search TERM:
    ./search.sh "{{TERM}}"

# search torrents for matching title, output to STDOUT not pager
searchb TERM:
    ./search.sh --cron "{{TERM}}"

# recently uploaded last 25
recent:
    @sqlite3 yify.sqlite "select title, imdbid, year, rating, genres from yify order by rowid desc limit 25" | tr '|' '\t' | column -t -s$'\t'

# ordered by year, last 25
latest:
    @sqlite3 yify.sqlite "select title, imdbid, year, genres, url, date_uploaded from yify order by year desc limit 25;" | tr '|' '\t' | column -t -s$'\t'

# search on genre, order by year desc
genre TERM:
    @sqlite3 yify.sqlite "SELECT title, imdbid, year, genres, rating FROM yify WHERE genres like '%{{TERM}}%' ORDER BY year DESC LIMIT 200 ;" | tr '|' '\t' | column -t -s$'\t'

# family movies, not animation, should put into file and view
family:
    @sqlite3 yify.sqlite "SELECT title, imdbid, year, genres, rating FROM yify WHERE genres like '%family%' AND genres not like '%animation%' AND rating > 5.0 ORDER BY year DESC LIMIT 1000 ;" | tr '|' '\t' | column -t -s$'\t'

# count of titles
count:
    @sqlite3 yify.sqlite "SELECT count(rowid) FROM yify "

# max rowid of database
max:
    @sqlite3 yify.sqlite "SELECT max(rowid) FROM yify "

imdbj:
  #!/usr/bin/env bash
  DIR=$JSONDIR
  for tt in $(grep imdbid latest.txt | cut -f2 -d'=' | tr -d ' ')
  do
    file="$JSONDIR/$tt.json"
    if [[ -f $file ]]; then
      jq '{ title: .Title, Year: .Year, Rating: .imdbRating, Genre: .Genre, Language: .Language, Director: .Director, Actors: .Actors, Plot: .Plot, imdbid: .imdbID }' $file
    fi
  done

# gets data for latest movies from imdb database which contains director
#  and actor.
#  NOTE: if latest.sh does not run (due to no connection to yts.mx)
#  then latest.txt does not get created so this will not run.
#  NOTE: often rating in yify is wrong. We should sort on imdbrating
imdb:
  #!/usr/bin/env bash
  DB=$JSONDIR/imdb.sqlite
  LAST_ID=$(tail -1 last_imdb.txt)
  sqlite3 yify.sqlite "SELECT imdbid FROM yify WHERE rowid > $LAST_ID AND genres NOT like '%horror%' AND genres not like '%adult%' ORDER BY rating DESC LIMIT 100;" > t.tt
  for tt in $(cat t.tt)
  do
    sqlite3 -line $DB "SELECT title, year, imdbrating, genre, language, country, director, actors, imdbid, plot FROM imdb WHERE imdbid=\"$tt\""
    sqlite3 -line yify.sqlite "SELECT url FROM yify WHERE imdbid=\"$tt\""
    echo

  done > imdb.txt
  sqlite3 yify.sqlite "SELECT max(rowid)    FROM yify " >> last_imdb.txt
  cat imdb.txt | /Users/rahul/bin/mail.sh -s "Latest IMDB" rahul2012@gmail.com

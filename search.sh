#!/usr/bin/env bash 
# ----------------------------------------------------------------------------- #
#         File: search.sh
#  Description: search for movies in YIFY torrents based on title genre and year
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-04-09 - 09:01
#      License: MIT
#  Last update: 2019-02-19 14:36
# ----------------------------------------------------------------------------- #
#  search.sh  Copyright (C) 2012-2018 j kepler
# CHANGELOG ---
# 2019-02-19 - can use imdbid as parameter
# ------------
# TODO SECTION --
# TODO add status to it so we can see movies of interest, seen, best, etc
# TODO option to ignore movies of a genre

## 2019-02-15 - replace t.t with tempfile due to folder action here
TMPFILE=$( mktemp /tmp/example.XXXXXXXXXX ) || exit 1


#source ~/bin/sh_colors.sh
# pdone pinfo perror preverse pdebug pverbose



#===  FUNCTION  ================================================================
#         NAME:  usage
#  DESCRIPTION:  Display usage information.
#===============================================================================
function usage ()
{
	cat <<- EOT

  Usage :  ${0##/*/} [options] [--] args

  Options: 
  -t, --title      title or part of title
  -y, --year       year of release
  -g, --genre      genre of movie
  -h, --help       Display this message
  -v, --version    Display script version
  -V, --verbose    Display processing information
  --cron           Not interactive
  --no-verbose     Suppress extra information
  --debug          Display debug information

	EOT
}    # ----------  end of function usage  ----------


#-------------------------------------------------------------------------------
# handle command line options
#-------------------------------------------------------------------------------
OPT_VERBOSE=
OPT_DEBUG=
OPT_YEAR=
OPT_GENRE=
OPT_TITLE=
QUERY=""
OPT_OPT=
OPT_STATUS=
while [[ $1 = -* ]]; do
case "$1" in
    -t|--title)   shift
                     OPT_TITLE=$1
                     OPT_OPT=1
                     shift
                     ;;
    -y|--year)   shift
                     OPT_YEAR=$1
                     OPT_OPT=1
                     shift
                     ;;
    -g|--genre)   shift
                     OPT_GENRE=$1
                     OPT_OPT=1
                     shift
                     ;;
    --imdbid)   shift
                     OPT_ID=$1
                     OPT_OPT=1
                     shift
                     ;;
    -s|--status)   shift
                     OPT_STATUS=$1
                     OPT_OPT=1
                     shift
                     ;;
    -V|--verbose)   shift
                     OPT_VERBOSE=1
                     ;;
    --no-verbose)   shift
                     OPT_VERBOSE=
                     ;;
    --cron)        shift
                     OPT_CRON=1
                     export PATH="/usr/local/bin:/usr/local/sbin:$PATH:/Users/rahul/bin"
                     ;;
    --debug)        shift
                     OPT_DEBUG=1
                     ;;
    -h|--help)
        usage
        exit
    ;;
    *)
        echo "$0 Error: Unknown option: $1" >&2   # rem _
        echo "Use -h or --help for usage" 1>&2
        exit 1
        ;;
esac
done
cd ~/work/projects/yts/

if [[ $# -gt 0 ]]; then
    # 2019-02-19 - check for imdbid
    if [[ $1 = *tt[0-9][0-9]* ]]; then
        OPT_ID=$1
    else
        OPT_TITLE="$*"
        echo "setting title to $OPT_TITLE" 1>&2
    fi
    OPT_OPT=1
fi
if [[ -z $OPT_OPT ]]; then
    echo "I got no query. Enter pattern:" 1>&2
    echo -n "Title   :"
    read OPT_TITLE
    echo -n "Year    :"
    read OPT_YEAR
    echo -n "Genre    :"
    read OPT_GENRE
else
        # red call/output picks up error anyway as output
        #echo "Got $*" 1>&2
        >&2 echo "Got $*"
    #echo "Got $1"
    #OPT_TITLE="$1"
    #echo "xxx setting title to $OPT_TITLE"
fi
LIMIT=" LIMIT 100"
if [[ -n "$OPT_TITLE" ]]; then
    QUERY="WHERE TITLE LIKE \"%${OPT_TITLE}%\""
else
    QUERY="WHERE 1=1 "
fi
if [[ -n "$OPT_ID" ]]; then
    QUERY="$QUERY AND IMDBID=\"$OPT_ID\" "
fi
if [[ -n "$OPT_YEAR" ]]; then
    QUERY="$QUERY AND YEAR=$OPT_YEAR "
fi
if [[ -n "$OPT_GENRE" ]]; then
    QUERY="$QUERY AND GENRES LIKE \"%${OPT_GENRE}%\""
fi
if [[ -n "$OPT_STATUS" ]]; then
    QUERY="$QUERY AND STATUS = \"${OPT_STATUS}\""
fi

if [[ -n "$OPT_VERBOSE" ]]; then
    echo "QUERY: $QUERY"
fi
sqlite3 yify.sqlite "SELECT id, imdbid, title, year, rating, genres, url FROM yify ${QUERY} $LIMIT" | column -t -s'|' > $TMPFILE
if [[ -n $OPT_CRON ]]; then
    cat $TMPFILE
    exit 0
fi
if [[ -s "$TMPFILE" ]]; then
    most $TMPFILE
    wc -l $TMPFILE
else
    echo "No results "
fi
\rm $TMPFILE

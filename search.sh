#!/usr/bin/env bash 
# ----------------------------------------------------------------------------- #
#         File: search.sh
#  Description: search for movies in YIFY torrents based on title genre and year
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-04-09 - 09:01
#      License: MIT
#  Last update: 2018-04-19 08:41
# ----------------------------------------------------------------------------- #
#  search.sh  Copyright (C) 2012-2018 j kepler
# TODO add status to it so we can see movies of interest, seen, best, etc
# TODO option to ignore movies of a genre

# so gnu coreutils override the old BSD ones
export PATH="$(brew --prefix coreutils)/libexec/gnubin:/usr/local/bin:$PATH"
# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__root="$(cd "$(dirname "${__dir}")" && pwd)" # <-- change this
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"

arg1="${1:-}"

source ~/bin/sh_colors.sh
# pdone pinfo perror preverse pdebug pverbose
APPNAME=$( basename $0 )
ext=${1:-"default value"}
TODAY=$(date +"%Y-%m-%d-%H%M")
curdir=$( basename $(pwd))
#set -euo pipefail
TAB=$'\t'
#IFS=$'\n\t'



ScriptVersion="1.0"

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
if [[ $# -gt 0 ]]; then
    OPT_TITLE="$*"
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
    echo "Got $*" 1>&2
    #echo "Got $1"
    OPT_TITLE="$1"
fi
LIMIT=" LIMIT 100"
if [[ -n "$OPT_TITLE" ]]; then
    QUERY="WHERE TITLE LIKE \"%${OPT_TITLE}%\""
else
    QUERY="WHERE 1=1 "
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
sqlite3 yify.sqlite "SELECT id, imdbid, title, year, genres FROM yify ${QUERY} $LIMIT" | column -t -s'|' > t.t
most t.t

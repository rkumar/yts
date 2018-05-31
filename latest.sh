#!/usr/bin/env bash 
#===============================================================================
#
#          FILE: latest.sh
# 
#         USAGE: ./latest.sh 
# 
#   DESCRIPTION:  fetch the latest movies uploaded on y t s.
#                 Compare to id.tsv to see which are not in our database.
#                 Send the latest list by mail.
# 
#       OPTIONS: --cron
#  REQUIREMENTS: uses sponge and mail.sh
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 04/03/2018 12:48
#      REVISION:  2018-04-03 12:53
#===============================================================================
# NOTE: the data has an uploaded date, we can check that, to see what is new
# As of 2018-04-27 wget has been failing with SSL on this site and wikipedia.
#  `curl` giving the same SSL problem.

arg1="${1:-}"

# use ,fh to generate file header
source ~/bin/sh_colors.sh
# pdone pinfo perror preverse pdebug pverbose
APPNAME=$( basename $0 )
ext=${1:-"default value"}
TODAY=$(date +"%Y-%m-%d-%H%M")
# 2018-04-16 - removing time so it is easy to import todays file
TODAY=$(date +"%Y-%m-%d")
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
OPT_CRON=
while [[ $1 = -* ]]; do
case "$1" in
    -f|--filename)   shift
                     filename=$1
                     shift
                     ;;
    -V|--verbose)   shift
                     OPT_VERBOSE=1
                     ;;
    --no-verbose)   shift
                     OPT_VERBOSE=
                     ;;
    --debug)        shift
                     OPT_DEBUG=1
                     ;;
    --cron)        shift
                     OPT_CRON=1
                     PATH=$PATH:/usr/local/bin:/Users/rahul/bin/
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
cd /Users/rahul/work/projects/yts
OUT=list-movies-${TODAY}.json
GZ=${OUT}.gz

#wget -q -O $GZ https://yts.am/api/v2/list_movies.json?limit=50
wget --no-check-certificate -O $GZ https://yts.am/api/v2/list_movies.json?limit=50
gunzip $GZ


PENDING=pending.txt
json/json.rb $OUT >> $PENDING
sort -u $PENDING | sponge $PENDING
sort -n -k1 $PENDING | sponge $PENDING
[[ -z "$OPT_CRON" ]] && wc -l $PENDING

#tail t.new
diff --unified $PENDING id.tsv | grep '^-\d' | cut -c2- > latest.txt
if [[ -s "latest.txt" ]]; then
    [[ -z "$OPT_CRON" ]] && echo "Sending latest by mail"
    cat latest.txt | column -t -s$'\t' | /Users/rahul/bin/mail.sh -s "Latest YIFY" rahul2012@gmail.com
    [[ -z "$OPT_CRON" ]] && echo "Need to append these to id.tsv using append.sh"
else
    [[ -z "$OPT_CRON" ]] && echo "Nothing new added "
    #cat t.new
fi
[[ -z "$OPT_CRON" ]] && echo "once you have updated id.tsv using append.sh, you can delete $PENDING"
[[ -z "$OPT_CRON" ]] && echo "you must run ./import.rb $OUT"

#!/usr/bin/env zsh 



# so gnu coreutils override the old BSD ones
export PATH="$(brew --prefix coreutils)/libexec/gnubin:/usr/local/bin:$PATH"
# Set magic variables for current file & dir

# use ,fh to generate file header
source ~/bin/sh_colors.sh
# pdone pinfo perror preverse pdebug pverbose



ScriptVersion="1.0"

#===  FUNCTION  ================================================================
#         NAME:  usage
#  DESCRIPTION:  Display usage information.
#===============================================================================
function usage ()
{
	cat <<- EOT

  Usage :  ${0##/*/} -d movie.sqlite -t movie [options] <rowid> <column_name>

  Options: 
  -d, --dbname     DAtabase Name
  -t, --tbname     TAble Name
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
DBNAME=
TBNAME=
while [[ $1 = -* ]]; do
case "$1" in
    -d|--db)   shift
                     DBNAME=$1
                     shift
                     ;;
    -t|--table)   shift
                     TBNAME=$1
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

if [[ -z "$DBNAME" ]]; then
    perror "I got no DBNAME"
    exit 1
fi
if [[ -z "$TBNAME" ]]; then
    perror "I got no TBNAME"
    exit 1
fi
if [ $# -eq 0 ]
then
    echo "I got no rowid" 1>&2
    exit 1
else
    echo "Got $*" 1>&2
    #echo "Got $1"
    if [[ ! -f "$DBNAME" ]]; then
        echo "File:$1 not found" 1>&2
        exit 1
    fi
fi
rowid=$1
shift


## loop through columns given on command line and run update on them one by one
while [ "$1" != "" ]; do

    col=$1
    TITLE=$(sqlite3 $DBNAME "select $col from $TBNAME where rowid = $rowid")
    pbold "Row: $rowid. $col: ($TITLE)"
    # vared not working with /usr/local/bin/zsh. works with /bin/zsh
    vared TITLE
    
    [[ -z "$TITLE" ]] && { echo "${X_MARK} Error: $col blank." 1>&2; exit 1; }
   #read TITLE
    sqlite3 $DBNAME "update $TBNAME set $col = '"$TITLE"' where rowid = $rowid"
    shift

    pinfo "${CHECK_MARK} Updated $col "
    sqlite3 -line $DBNAME "select rowid, $col from $TBNAME where rowid = $rowid"
done

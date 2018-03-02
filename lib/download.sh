# Just assume that at minimum libload has already been loaded
libload debug.sh die.sh

# Download a file atomically. wget is used to download the file to a temporary
# file in the target directory, then a mv is done. If the target file already
# exists the download is skipped.
#
# First two arguments must be url and destination. Any additional args are passed to wget.
download() (
debug 11 "${FUNCNAME[0]}( $@ )"
[ $# -ge 2 ] || die 1 "${FUNCNAME[0]}: invalid use"
url=$1
dest=$2
shift 2

if echo $url | egrep -q '/$'; then
  die 1 "url ($url) may not be a directory"
fi
urlfile=$(basename $url) || die $? "basename failed"

if echo "$dest" | egrep -q '/$'; then
  # dest is a directory; append basename from url
  target=$dest$urlfile
else
  target=$dest
fi

if [ -e "$target" ]; then
  [ -r "$target" ] || die 2 "$target exists but is not readable"

  debug 1 "$target already exists; skipping download"
  return
fi

tmp=$(mktemp $target.XXXXXX) || die $? "mktemp failed"
debug_vars 19 url dest urlfile target

if [ $DEBUG -le 0 ]; then
  echo "Downloading $urlfile"
  opt='-o /dev/null'
else
  debug 1 "Downloading $url to $target"
fi


# For some reason mv fails when DEBUG > 0
( wget -O "$tmp" $opt "$@" "$url" && DEBUG=0 mv "$tmp" "$target" ) || die $? "error downloading $url"
)

# vi: expandtab sw=2 ts=2

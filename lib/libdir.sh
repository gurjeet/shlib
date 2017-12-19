[ -n "$libdir" ] || { echo "$(caller): \$libdir must be set" 1>&2; exit 99; }

# Get an absolute path
libdir="$(cd "$libdir"; pwd)"

# Set convenience variables
SCRIPTDIR=${SCRIPTDIR:-"$(cd "$(dirname "$0")"; pwd)"}
SCRIPTNAME=${SCRIPTNAME:-"$(basename "$0")"}

# Do this the hard way so we're not pulling in debug.sh
if [ -n "$DEBUG" ]; then if [ "$DEBUG" -ge 90 ]; then
  echo "$(caller): libload: \$0=$0 \$libdir=$libdir \$SCRIPTDIR=$SCRIPTDIR \$SCRIPTNAME=$SCRIPTNAME" 1>&2
fi; fi

libload() {
  # Do this the hard way so we're not pulling in debug.sh
  if [ -n "$DEBUG" ]; then if [ "$DEBUG" -ge 90 ]; then
    echo "$(caller): libload: loading $@" 1>&2
  fi; fi

  local load
  for f in "$@"; do
      load="$libdir"/"$f"
      
      # BUG: for some reason set -e doesn't recognize this as being part
      # of an if, which means the if block doesn't execute.
      if ! . $load; then
        echo "FATAL: error sourcing $load" 1>&2
        exit 99
      fi
  done
}

# vi: expandtab ts=2 sw=2

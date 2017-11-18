[ -n "$libdir" ] || { echo "$(caller): \$libdir must be set" 1>&2; exit 99; }

# Get an absolute path
libdir="$(cd "$libdir"; pwd)"

libload() {
  local load
  load="$libdir"/"$1"
  
  # BUG: for some reason set -e doesn't recognize this as being part
  # of an if, which means the if block doesn't execute.
  if ! . $load; then
    echo "FATAL: error sourcing $load" 1>&2
    exit 99
  fi
}

set -e
[ -n "$libdir" ] || { echo "$(caller): \$libdir must be set" 1>&2; exit 99; }
. $libdir/libdir.sh
libload debug.sh

# WARNING: Don't use && in here! It won't work correctly with -e. In other
# scripts that's pretty obvious, but these functions are generally only called
# when there's already a problem, so it ends up being very confusing!

error() {
  while [ "$1" = "-c" -o "$1" = "-n" ]; do
    if [ "$1" = "-n" ]; then
      lineno=$2
      shift 2
    fi
    if [ "$1" = "-c" ]; then
      local stack=0
      shift
    fi
  done

  echo "$@" 1>&2
  if [ -n "$stack" ]; then
    stacktrace 1 # Skip our own frame
  else
    [ -z "$lineno" ] || echo "File \"$0\", line $lineno" 1>&2
  fi
}

die() {
  return=$1
  debug_vars 99 return
  shift
  error "$@"
  [ $DEBUG -le 0 ] || stacktrace 1
  if [ -n "$DIE_EXTRA" ]; then
    local lineno=''
    error
    error $DIE_EXTRA
  fi
  exit $return
}

# vi: expandtab sw=2 ts=2

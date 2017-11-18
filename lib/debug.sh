debug() {
  local level=$1
  shift
  if [ $level -le $DEBUG ] ; then
    local old_IFS
    old_IFS=$IFS
    unset IFS
    # Output debug level if it's over threashold
    if [ $DEBUG -ge ${DEBUGEXTRA:-10} ]; then
      echo "${level}: $@" 1>&2
    else
      echo "$@" 1>&2
    fi
    IFS=$old_IFS
  fi
}

debug_vars () {
  level=$1
  shift
  local out=''
  local value=''
  for variable in $*; do
    eval value=\$$variable
    out="$out $variable='$value'"
  done
  debug $level $out
}

debug_sanity() {
  # Ensure that DEBUG is set
  if [ ${DEBUG:-0} = 0 ] ; then
    [ -n "$1" ] && error "WARNING: \$DEBUG not set"
    DEBUG=0
  fi
}
debug_sanity

stacktrace () {
  debug 200 "stacktrace( $@ )"
  local frame=${1:-0}
  local line=''
  local file=''
  debug_vars 200 frame line file

  # NOTE the stderr redirect below!
  (
    echo
    echo Stacktrace:
    while caller $frame; do
      frame=$(( $frame + 1 ))
    done | while read line function file; do
      if [ -z "$function" -o "$function" = main ]; then
        echo "$file: line $line"
      else
        echo "$file: line $line: function $function"
      fi
    done
  ) 1>&2
}

# vi: expandtab sw=2 ts=2

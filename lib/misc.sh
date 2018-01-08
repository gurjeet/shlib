# This file is meant to be *sourced*, not executed!

[ -n "$libdir" ] || { echo "$(caller): \$libdir must be set" 1>&2; exit 99; }
. $libdir/libdir.sh
libload die.sh

# Verify that each variable specified has a non-empty value
checkVarsNotEmpty () {
  local variable
  local value
  for variable in $*; do
    eval value=\$$variable
    [ -n "$value" ] || die 1 "$variable must be set"
  done
}

# Verify that each variable specified is empty
checkVarsEmpty () {
  local variable
  local value
  for variable in $*; do
    eval value=\$$variable
    [ -z "$value" ] || die 1 "$variable must not be set"
  done
}

brewCheck(){
  # WARNING: this is untested!
  exe=$1
  local resp
  if ! which -s $exe; then
    read -p "could not find $exe, should I install it via brew?" resp
    case "$resp" in
      [Yy]|[Yy][Ee]|[Yy][Ee][Ss])
        brew install $exe
        ;;
      *)
        die 1 "Please install $exe or ensure it is in your path."
    esac

    # Double-check that it's now available
    which -s $exe || die 1 "$exe still not found after install... \$PATH set correctly?"
  fi
}

# vi: expandtab sw=2 ts=2

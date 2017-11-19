# This file is meant to be *sourced*, not executed!

[ -n "$libdir" ] || { echo "$(caller): \$libdir must be set" 1>&2; exit 99; }
. $libdir/libdir.sh
libload die.sh

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

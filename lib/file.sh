# This file is meant to be *sourced*, not executed!

[ -n "$libdir" ] || { echo "$(caller): \$libdir must be set" 1>&2; exit 99; }
. $libdir/libdir.sh
libload die.sh

getTemp() {
  echo ${TMPDIR:-${TMP:-${TEMP:-/tmp}}}
}

tempFile() {
  echo "$1" | grep -q XXX || die "invalid call to tempFile"
  mktemp /`getTemp`/$1
}

tempDir() {
  echo "$1" | grep -q XXX || die "invalid call to tempDir"
  mktemp -d /`getTemp`/$1
}

relativePath() {
  [ $# -ge 1 ] || die 99 "must specify source to relativePath()"

  local source="$1"
  shift

  local target="$1"
  if [ -z "$target" ]; then
    target=`pwd`
  else
    shift
  fi

  [ $# -eq 0 ] || die 99 "unexpected parameters to relativePath(): $@"

  debug 9 python -c "import os.path; print os.path.relpath('$source', '$target')" || die 98 "python returned $?"
  python -c "import os.path; print os.path.relpath('$source', '$target')" || die 98 "python returned $?"
}

# See if a file in in $PATH
checkPath() {
    if ! which "$1" > /dev/null; then
        echo "$1 does not exist or is not in \$PATH"
        return 1
    fi
}

# Similar to checkPath, but allows use with an arbitrary path
findInPath() {
  local old_IFS
  old_IFS=$IFS
  local f
  f="$1"
  shift

  debug 9 "Looking for $f in these locations: $@"
  IFS=':'
  for d in $@; do # Note: we intentionally don't quote $@
    debug 19 "Looking for $d/$f"
    
    if [ -r "$d/$f" ]; then
      echo "$d/$f"
      IFS="$old_IFS"
      return
    fi
  done
  IFS="$old_IFS"
  return 1
}


file_sanity() {
  debug 1 "file_sanity() is deprecated; please use fileSanity()"
  fileSanity "$@"
}
fileSanity() {
  for file in "$@"; do
    [ -e "$file" ] || die 1 "error: file '$file' does not exist"
    [ -r "$file" ] || die 1 "error: file '$file' is not readable"
  done
}

dir_sanity() {
  debug 1 "dir_sanity() is deprecated; please use fileSanity()"
  fileSanity "$@"
}
dirSanity() {
  debug 81 "dir_sanity($@)"
  for dir in "$@"; do
    [ -e "$dir" ] || die 1 "error: dir '$dir' does not exist"
    [ -d "$dir" ] || die 1 "error: '$dir' is not a directory"
    # Test for execute? Seems kinda pointless to get a dir you can't do anything with...
    [ -x "$dir" ] || die 1 "error: dir '$dir' is not executable"
  done
}

# vi: expandtab sw=2 ts=2

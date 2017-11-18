# This file is meant to be *sourced*, not executed!

# WARNING: This script makes some (potentially surprising) changes to
# the environment. See the commands at the bottom of the file for
# details.

# This is modified from https://github.com/decibel/db_tools/blob/master/lib/util.sh

[ -n "$libdir" ] || { echo "$(caller): \$libdir must be set" 1>&2; exit 99; }
. $libdir/libdir.sh
libload die.sh

# Set convenience variable. Unlike other env modification we do this
# here so other lib stuff can use it if necessary
SCRIPTDIR="$(cd "$(dirname "$0")"; pwd)"
SCRIPTNAME="$(basename "$0")"

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

# Verify that submodules are initialized
submoduleCheck() {
  # Sadly all the git submodule commands seem to be insanely slow, but we want
  # this function to be fast so it can be run frequently.
  #
  # To work around this, we roll some of our own checks instead of relying on
  # git submodule directly.

  local gitdir=$(getGitTLD) || exit $?

  # First, get a list of registered submodules
  registered=$(grep '\[submodule "' "$gitdir"/.gitmodules | cut -d'"' -f2 | sort)

  # Next, a list of configured submodules
  configured=$(git -C "$gitdir" config --get-regexp '^submodule\.' | cut -d. -f2 | sort)

  debug_vars 8 registered
  debug_vars 8 configured

  if [ "$configured" != "$registered" ]; then
    echo "initializing submodules in $gitdir ..."
    debug 9 git -C "$gitdir" submodule update --init --recursive
    git -C "$gitdir" submodule update --init --recursive || die 98 "unable to init submodules. git returned $?"
    echo done
  fi
}

# Verify that symlinks exist in $destdir for $files from $submodule. Assumes
# submodules are in GitTLD/submodules.
#
# NOTE: if you're using this then you probably want to add $files to the
# relevant .gitignore... otherwise you just have permanent links, which makes
# calling this function rather pointless. (Or perhaps you actually want
# permanent links to begin with...)
submoduleCreateLinks() {
  local submodule=$1
  local destdir=$2
  shift 2
  local files=$@

  local srcdir="`getGitTLD`"/submodules/"$submodule"
  [ -d "$srcdir" ] || die 2 "$srcdir does not exist (are submodules initialized?)"

  local destfile
  local sourcefile
  # need to cd for ln anyway...
  (cd "$destdir"
    for f in $files; do
      sourcefile="$srcdir"/"$f"
      if ! [ -e "$f" ]; then
        local relative=`relativePath "$sourcefile"`
        debug 9 symlinking "$relative" to "$f"
        ln -s "$relative" "$f" || die 98 "ln -s $sourcefile $f returned $?"

        if [ -x "$sourcefile" ]; then
          chmod a+x "$f"
        fi
      fi
    done
  )
}

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

file_sanity() {
  for file in "$@"; do
    [ -e "$file" ] || die 1 "error: file '$file' does not exist"
    [ -r "$file" ] || die 1 "error: file '$file' is not readable"
  done
}

dir_sanity() {
  for dir in "$@"; do
    [ -e "$dir" ] || die 1 "error: dir '$dir' does not exist"
    [ -d "$dir" ] || die 1 "error: '$dir' is not a directory"
    # Test for execute? Seems kinda pointless to get a dir you can't do anything with...
    [ -x "$dir" ] || die 1 "error: dir '$dir' is not executable"
  done
}

getGitTLD(){
  [ -n "$SCRIPTDIR" ] || die 99 "SCRIPTDIR must be set to a directory underneath the Lynny-Whitebox repo"

  local tld
  tld=$(cd $SCRIPTDIR && git rev-parse --show-toplevel) || die 98 "unable to find git TLD"
  
  # Sanity-check it...
  dir_sanity "$tld"

  echo "$tld"
}

cdGitTLD(){
  dir=$(getGitTLD) || exit $?
  cd $dir || exit $?
}

gitDemandClean(){
  [ -z "$(cdGitTLD && git status --porcelain)" ] || die 1 "git checkout is not clean"
}

# Get the portion of a path that would identify where this repo lives
# in relation to the go environment
getGoGitRepoSubPath() {
  # This is kinda lame, but go mandates it anyway, so...
  echo "src/github.build.ge.com/Lynny/Lynny-Whitebox"
}

getDefaultGopath(){
  local git_tld
  git_tld="$(getGitTLD)"

  local gopath
  gopath="${git_tld%$(getGoGitRepoSubPath)}"

  # Sanity check it...
  dir_sanity "$gopath"

  echo "$gopath"
}

ExportGopath(){
  if [ -z "$GOPATH" ]; then
    export GOPATH="$(getDefaultGopath)"
  fi
  # TODO: Ensure at least first part of GOPATH is somewhere in PATH, because
  # that's where tools get installed
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

# vi: expandtab sw=2 ts=2

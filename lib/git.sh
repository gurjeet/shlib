[ -n "$libdir" ] || { echo "$(caller): \$libdir must be set" 1>&2; exit 99; }
. $libdir/libdir.sh
libload debug.sh die.sh file.sh

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

# Verify that submodules are initialized
submoduleCheck() {
  # Sadly all the git submodule commands seem to be insanely slow, but we want
  # this function to be fast so it can be run frequently.
  #
  # To work around this, we roll some of our own checks instead of relying on
  # git submodule directly.

  local gitdir=$(getGitTLD) || exit $?

  # First, get a list of registered submodules (that exist in .gitmodules)
  registered=$(grep '\[submodule "' "$gitdir"/.gitmodules | cut -d'"' -f2 | sort)

  # Next, a list of configured submodules (configured as in git config)
  configured=$(git -C "$gitdir" config --get-regexp '^submodule\..*\.url' | cut -d. -f2 | sort)

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

# vi: expandtab sw=2 ts=2

#
# This file must be SOURCED, not executed
#

# This is a simple loader script that is meant to pull in the base libload
# functionality, after ensuring that $libdir exists. If $libdir/../.lib.post.sh
# exists, it will be sourced after libdir.sh is loaded.

# libdir must be set for other scripts to work.
[ -n "$libdir" ] || libdir="$(dirname "$0")/lib"

if ! [ -d "$libdir" -o -L "$libdir" ]; then #     -L file       True if file exists and is a symbolic link.
  echo "library directory '$libdir' does not exist" 1>&2
  exit 1
fi

# If libdir.sh doesn't exist but it looks like we're in git with submodules
# configured, try doing a submodule init
if ! [ -e "$libdir"/libdir.sh ]; then
  echo "$libdir/libdir.sh does not exist, checking for git submodules"
  SCRIPTDIR=`dirname "$0"` # This would get set anyway...
  SHLIB_gittld=$(cd $SCRIPTDIR && git rev-parse --show-toplevel) || { echo "does not appear to be a git repo; aborting" 1>&2; exit 1; }
  if [ -e "$SHLIB_gittld"/.gitmodules ]; then
    echo "initializing submodules in $SHLIB_gittld ..."
    git -C "$SHLIB_gittld" submodule update --init --recursive || { echo "unable to init submodules. git returned $?" 1>&2; exit 1; }
    echo done
  fi    
fi

. "$libdir"/libdir.sh || { echo "Unable to load $libdir/libdir.sh" 1>&2; exit 1; }

if [ -r "$SCRIPTDIR"/.lib.post.sh ]; then
  # Do this the hard way so we're not pulling in debug.sh
  if [ -n "$DEBUG" ]; then if [ "$DEBUG" -ge 90 ]; then
    echo "sourcing $SCRIPTDIR/lib.post.sh" 1>&2
  fi; fi

  . "$SCRIPTDIR"/.lib.post.sh || { echo "Unable to load $SCRIPTDIR/lib.post.sh" 1>&2; exit 1; }
else
  # Do this the hard way so we're not pulling in debug.sh
  if [ -n "$DEBUG" ]; then if [ "$DEBUG" -ge 90 ]; then
    echo "$SCRIPTDIR/lib.post.sh does not exist; skipping" 1>&2
  fi; fi

fi

# vi: expandtab sw=2 ts=2

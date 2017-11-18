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

. $libdir/libdir.sh || { echo "Unable to load libdir.sh" 1>&2; exit 1; }

if [ -r "$libdir"/../.lib.post.sh ]; then
  . "$libdir"/../.lib.post.sh || { echo "Unable to load $libdir/../.lib.post.sh" 1>&2; exit 1; }
fi

# vi: expandtab sw=2 ts=2

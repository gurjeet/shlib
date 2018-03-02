# Just assume that at minimum libload has already been loaded
libload die.sh file.sh download.sh

# NOTE: many of these functions intentionally operate in a subshell instead of
# inline. Subshell versions are not indented.

# Install a version of go from a downloaded tarball. Does nothing if destination already exists.
goInstall() (
[ $# -eq 2 ] || die 1 "${FUNCNAME[0]}: invalid use"
tarball=$1
dest=$2

fileSanity "$tarball" || die $? "unable to install go from tarball $tarball"

# Go tarballs have a TLD of 'go/' already. Presumably caller doesn't want
# 'some_dir/go/go' as their install location, so strip trailing go if it's
# there.
dest=$(echo "$dest" | sed -e 's#go/*$##')

# Create dest if it doesn't exist; always sanity-check
(mkdir -p "$dest" && dirSanity "$dest") || die $? "unable to install $tarball at $dest"

if [ -d "$dest"/go ]; then
  debug 1 "$dest/go already exists; skipping install"
  exit
else
  echo "Installing $tarball to $dest"
fi

tmp=$(mktemp -d "$dest.XXXX") || die $? "unable to create temporary install directory"

# TODO: figure out how to use a trap to clean $tmp up without clobbering any existing trap.

if ! tar -C "$tmp" -xzf "$tarball"; then
  err="unable to untar $tarball to $tmp"
  if [ $DEBUG -gt 0 ]; then
    err="$err; leaving $tmp behind for investigation. Make sure to clean it up when done!"
  else
    rm -rf "$tmp" || true # Ignore any error from rm
  fi
  die 1 "$err"
fi

# mv is unhappy about DEBUG being <> 0...
DEBUG=0 mv "$tmp"/go "$dest"
rc=$?

# Doesn't seem worth leaving anything behind even on failure
rm -rf "$tmp" || true # ignore failure of rm

if [ $rc -ne 0 ]; then
  die $rc "unable to mv $tmp/go to $dest"
fi
)

# Get the URL for a specific go architecture and version. Sanity-checks version
# number but not architecture. TODO: try to determine actual URL from the
# download page (https://golang.org/dl/).
goVersionURL() {
  # goTarball does sanity checking for us
  goURLFromTarball $(goTarball "$1" "$2")
}

# Returns download URL for a valid go tarball. Does no sanity checking.
goURLFromTarball() {
  echo "https://dl.google.com/go/go$1"
}

# Return canonical tarball filename for given arch and version
goTarball() (
debug 11 "${FUNCNAME[0]}( $@ )"
[ $# -eq 2 ] || die 1 "${FUNCNAME[0]}: invalid use"
arch=$1
version=$2

# Verify version is sane.
goMightBeMajorVersion "$version" || goIsMinorVersion "$version" || die $? "${FUNCNAME[0]}: invalid version"

echo "$version.$arch.tar.gz"
)

# Get the URL for the latest release of a particular architecture and major version.
goLatestVersionURL() (
debug 11 "${FUNCNAME[0]}( $@ )"
[ $# -eq 2 ] || die 1 "goLatestVersionURL requires architecture and major version"
arch=$1
major=$2

version=$(goMostRecentFromMajor)
rc=$?
[ $rc -eq ] || exit $rc

goVersionURL "$arch" "$version"
)

# Returns an exact go version. If the input is already an exact version it is
# returned. If the input is only a major version (ie: 1.10), the most recent
# full version is returned.
#
# An input with a 0 patch level (ie: 1.10.0) is treated as an exact version,
# but converted to the canonical go form with no patch level (ie: 1.10), even
# though that looks like it could be just a major version number.
goEnsureExactVersion() {
  debug 11 "${FUNCNAME[0]}( $@ )"
  [ $# -eq 1 ] || die 1 "${FUNCNAME[0]}: invalid use"
  local version=$1

  if goIsMinorVersion "$version"; then
    # At this point we know we have something of the form 1.2.??, so we can
    # simply strip off the trailing .0 if present and return.
    echo "$version" | sed -e 's/\.0$//'
  else
    # goMostRecentFromMajor already checks for this, but lets provide a more
    # explicit error message. Subshell so it's error can't terminate us.
    ( goMightBeMajorVersion "$version" ) || die 1 "$version is not a valid go version specifier"

    goMostRecentFromMajor "$version"
  fi
}

# Returns 0 if input is a major version. Note that golang does not do .0
# releases (ie: 1.10 is the first 1.10 release, not 1.10.0), hence the odd name
# for the function.
# Returns 1 if input definitely isn't a major version.
# Returns >1 for any error.
goMightBeMajorVersion() {
  debug 11 "${FUNCNAME[0]}( $@ )"
  [ $# -eq 1 ] || die 2 "${FUNCNAME[0]}: invalid use"
  echo "$1" | egrep -q '^[0-9]+\.[0-9]+$'
}

# Returns 0 if input is a valid full go version (not counting architecture).
# Returns 1 if input isn't a full go version.
# Returns >1 for any error.
goIsMinorVersion() {
  [ $# -eq 1 ] || die 2 "${FUNCNAME[0]}: invalid use"
  echo "$1" | egrep -q '^[0-9]+(\.[0-9]+){2}$'
}

# Get the most recent minor version for a given major version. This is pulled
# from the golang git repository, and it assumes that git is installed. Returns
# a status of 98 if a valid major version is not supplied, and 99 if no version
# was found.
goMostRecentFromMajor() (
debug 11 "${FUNCNAME[0]}( $@ )"
set +o pipefail
major=$1

goMightBeMajorVersion "$major" || die 98 "$major is not a valid major version"

# Get the sorted versions, filter on major, and get the last one.
# Not the most efficient way, but meh.
#
# Make sure $major only matches beginning of each line!
latest=$(goVersions | egrep "^$major" | tail -n 1)
rc=$?
[ $rc -eq 1 ] && die 99 "no versions found matching $major"
[ $rc -eq 0 ] || die $rc "unable to find most recent go version for major $major"

echo "$latest"
)

# Get all released versions (based on what's in the golang git repo). Output is
# sorted oldest to most recent.
goVersions() (
set +o pipefail

# TODO: allow reversing ordering

# Yes, the sort may be pointless in some cases, but we're already making a
# *network call* to get the version list, so the cost of sort will be trivial
# in comparison.
#
# See https://stackoverflow.com/questions/4493205/unix-sort-of-version-numbers for sort info
goGitReleaseTags | egrep -o '[0-9]+(\.[0-9]+){1,2}$' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n
)

# Get tags for released versions
goGitReleaseTags() (
debug 11 "${FUNCNAME[0]}( $@ )"
set +o pipefail

# Sample input...
# 2b7a7b710f096b1b7e6f2ab5e9e3ec003ad7cd12	refs/tags/go1.7.6
# 3c6b6684ce21c1092ba208a0f1744ad7c930248a	refs/tags/go1.7beta1
# fca9fc52c831ab6af56e30f8c48062a99ded2580	refs/tags/go1.7beta2
# 53da5fd4d431881bb3583c9790db7735a6530a1b	refs/tags/go1.7rc1
#
# The regex looks for 'go#', then 1 or 2 instances of '.#', then EOL, where #
# means a number.
goGitTags | egrep 'go[0-9]+(\.[0-9]+){1,2}$'
)

# Get a list of all tags in the git repo
goGitTags() (
url=https://github.com/golang/go.git

debug 19 running git ls-remote --tags $url

rc=0
for i in 1 2 3; do
  timeout 2 git ls-remote --tags $url || rc=$?
  case $rc in
    0)    return ;; # success
    124)  ;; # timeout, continue loop
    *)    die $rc "retrieving git tags from $url failed" ;;
  esac
done
die 124 "retrieving git tags from $url timed out"
)


# Load a go dependency, but only if it doesn't exist
goGetIfMissing() {
    local commandName="$1"
    shift
    
    checkPath "$commandName" || goGet "$@"
}

goGetPackagesIfMissing() {
    for pkg in "$@"; do
        goCheckPackage "$pkg" || goGet "$pkg"
    done
}

goCheckPackage() {
    [ $# -eq 1 ] || die 2 "goCheckPackage takes only one argument, not $#"

    pkg="$1"

    [ -r "vendor/$pkg" ] || findInPath "src/$pkg" "$GOROOT" "$GOPATH" > /dev/null
}

goGet() {
    local get
    get="go get -v $getOptions $@"
    get=$(echo $get | tr -s ' ') # Get rid of potential double spaces
    echo "Running $get"
    $get
}

getDefaultGopath(){
  local git_tld
  git_tld="$(getGitTLD)"

  local gopath
  gopath="${git_tld%$(getGoGitRepoSubPath)}"

  # Sanity check it...
  dirSanity "$gopath"

  echo "$gopath"
}

ExportGopath(){
  if [ -z "$GOPATH" ]; then
    export GOPATH="$(getDefaultGopath)"
  fi
  # TODO: Ensure at least first part of GOPATH is somewhere in PATH, because
  # that's where tools get installed
}

# implement /usr/bin/timeout only if it doesn't exist
# From https://stackoverflow.com/a/31146904
[ -n "$(type -p timeout 2>&1)" ] || function timeout { (
    set -m +b
    sleep "$1" &
    SPID=${!}
    ("${@:2}"; RETVAL=$?; kill ${SPID}; exit $RETVAL) &
    CPID=${!}
    wait %1
    SLEEPRETVAL=$?
    if [ $SLEEPRETVAL -eq 0 ] && kill ${CPID} >/dev/null 2>&1 ; then
      RETVAL=124
      # When you need to make sure it dies
      #(sleep 1; kill -9 ${CPID} >/dev/null 2>&1)&
      wait %2
    else
      wait %2
      RETVAL=$?
    fi
    return $RETVAL
) }

# vi: expandtab sw=2 ts=2

# Just assume that at minimum libload has already been loaded
libload die.sh

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

# vi: expandtab sw=2 ts=2

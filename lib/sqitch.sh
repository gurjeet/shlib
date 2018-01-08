# Just assume that at minimum libload has already been loaded
libload git.sh

# TODO: all these functions should really start with `sqitch`

# Create a URI-DB (https://github.com/theory/uri-db/). Except for DB Name,
# inputs are in URI order. Arguments 6+ are treated as key+value options to add
sqitchBuildURI()(
  dbName="$1"
  user="$2"
  pw="$3"
  host="$4"
  port="$5"
  shift 5

  for item in "$@"; do
    query="$query${query:+&}$item"
  done
  query="${query:+?}$query"

  # userInfo
  if [ -n "$user" -o -n "$pw" ]; then
    userInfo="$user"

    # If we have a password, append it
    [ -z "$pw" ] || userInfo="$userInfo:$pw"

    # No matter what, we need a trailing @
    userInfo="$userInfo@"
  fi

  port="${port:+:}$port"

  authority="${userInfo}${host}${port}"

  echo "db:pg://$authority/${dbName}$query"
)

# sqitch TLD happens to also be git TLD
getSqitchTLD(){
  getGitTLD
}
cdSqitchTLD(){
  cdGitTLD
}

# Unlike SqitchTLD, TOPDIR is the directory that the plan file is in. It's also where the deploy stuff is.
getSqitchTOPDIR(){
  local d=$(sqitchConfGet core.top_dir) || exit $?
  echo "$(getSqitchTLD)/$d/"
}
cdSqitchTOPDIR(){
  local dir=$(getSqitchTOPDIR) || exit $?
  debug 5 "cd '$dir'"
  cd "$dir" || exit $?
}

sqitchConfGet() {
  ( cdSqitchTLD && sqitch config --get $1 )
}

sqitchSanity() {
  if [ -z "`sqitchConfGet user.email`" ]; then
    local getUser
    getUser="$libdir"/getSqitchUsername
    file_sanity "$getUser"

    read -p "Please enter your email address. It will be added to your per-user sqitch config: " email
    [ -z "$email" ] && die 3 "Email is required."

    sqitch config --user --add user.email "$email"

    current_user=`$getUser`
    read -p "sqitch is currently using '$current_user' for your user name. If you would like to change that, now's your chance. Just hit return to keep the current setting: " user
    [ -z "$user" ] && user="$current_user"
    sqitch config --user --add user.name "$user"
  fi
}

sqitchSanity

# vi: expandtab sw=2 ts=2

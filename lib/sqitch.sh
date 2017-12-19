# Just assume that at minimum libload has already been loaded
libload git.sh

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
    getUser="$SCRIPTDIR"/bin/lib/getSqitchUsername
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

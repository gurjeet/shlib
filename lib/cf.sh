# Just assume that at minimum libload has already been loaded
libload debug.sh
libload die.sh

CF_ERROR=${CF_ERROR:-9}

cfDie () {
    die $CF_ERROR $@
}

# Lookup functions

# Return the expected endpoint for a given environment
cfExpectedEndpoint() {
  [ $# -eq 1 ] || die 1 "invalid call to cfExpectedEndpoint $@"

  case "$1" in
    cf1)
      echo 'https://api.system.aws-usw02-pr.ice.predix.io'
      ;;
    cf3)
      echo 'https://api.system.aws-usw02-dev.ice.predix.io'
      ;;
    fra)
      echo 'https://api.system.aws-eu-central-1-pr.ice.predix.io'
      ;;
    jp1|ap-northeast-1)
      echo 'https://api.system.aws-jp01-pr.ice.predix.io'
      ;;
    *)
      cfDie "unknown environment '$1'"
  esac
}

# TODO: cf target is depressingly slow; cache this stuff somehow
cfCurrentEndpoint () {
  local endpoint
  endpoint=$(cf target | grep -i 'API endpoint': | awk '{print $3}') || cfDie "unable to get current endpoint"
  debug_vars 9 endpoint
  echo $endpoint
}

cfCurrentSpace () {
  local space
  space=$(cf target | grep -i Space: | awk '{print $2}') || cfDie "unable to get current space"
  debug_vars 9 space
  echo $space
}

cfSetSpace () {
  local new="$1"
  shift

  local old=$(cfCurrentSpace)
  [ "$new" == "$old" ] || cf target -s "$new" || cfDie "unable to change to space $new"
  echo $old
}

# Validators
cfDemandEnvironmentIs () {
  local expected=$(cfExpectedEndpoint $@) # $@ to let it sanity-check input
  local actual=$(cfCurrentEndpoint)

  [ -n "$actual" -a "$actual" == "$expected" ] || cfDie "wrong cf target for $1; expected endpoint $expected, got $actual"
}

cfDemandSpaceIs () {
  [ $# -eq 1 ] || die "invalid call to cfSpaceIs $@"

  local actual=$(cfCurrentSpace)
  [ "$actual" == "$1" ] || cfDie "wrong cf target; expected space $1, got $actual"
}

cfExecInSpaceIgnoreError () {
  local space="$1"
  shift

  local old
  old=$(cfSetSpace "$space")

  trap "debug_vars 1 ? rc; cfSetSpace '$old' >/dev/null" ERR
  cf "$@" && rc=$? || rc=$?
  trap - ERR
  debug 1 "cf $@ returned $rc"

  cfSetSpace "$old"
  return $rc
}

cfExtractURL () {
  echo "Extracting host from deployed application ($APP_NAME, guid $APP_GUID)"
  HOST=$(cf curl /v2/apps/$APP_GUID/stats | jq -r '."0".stats.uris[0]')
  URL="https://${AUTH_USER}:${AUTH_PASS}@${HOST}"
  echo "URL is ${URL}"
}

# vi: expandtab sw=2 ts=2

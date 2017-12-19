# Just assume that at minimum libload has already been loaded
libload sqitch.sh

patchSanity(){
    echo "$patch_name" | grep -q ' ' && die 2 "patch names may not contain spaces"

    [ -n "$requirements" ] || die 2 "All patches must have at least one requirement"

    [ -n "$description" ] || die 2 "Description may not be blank"
}

patchParseReqs() {
    local reqs

    for r in $requirements; do
        reqs="$reqs -r $r"
    done

    echo $reqs
}


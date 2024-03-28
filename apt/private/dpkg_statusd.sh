#!/usr/bin/env bash
set -o pipefail -o errexit -o nounset

readonly bsdtar="$1"
readonly out="$2"
readonly control_path="$3"
readonly package_name="$4"
shift 4

include=(--include "^./control$" --include "^./md5sums$")

tmp=$(mktemp -d)
"$bsdtar" -xf "$control_path" "${include[@]}" -C "$tmp"

"$bsdtar" -cf - $@ --format=mtree "${include[@]}" --options '!gname,!uname,!sha1,!nlink,!time' "@$control_path" | \
awk -v pkg="$package_name" '{ 
    if ($1=="#mtree") {
        print $1; next
    };  
    sub(/^\.?\//, "", $1);
    $1 = "./var/lib/dpkg/status.d/" pkg "/" $1 " contents=./" $1; 
    print $0
}'  | "$bsdtar" $@ -cf "$out" -C "$tmp/" @-

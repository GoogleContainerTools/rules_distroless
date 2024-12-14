#!/usr/bin/env bash
set -o pipefail -o errexit -o nounset

readonly bsdtar="$1"
readonly coreutils="$2"
readonly out="$3"
readonly control_path="$4"
readonly package_name="$5"
shift 5

include=(--include "^./control$" --include "^./md5sums$")

tmp=$($coreutils mktemp -d)
"$bsdtar" -xf "$control_path" "${include[@]}" -C "$tmp"

"$bsdtar" -cf - "$@" --format=mtree "${include[@]}" --options '!gname,!uname,!sha1,!nlink,!time' "@$control_path" | \
while IFS= read -r line; do
   first_field=$(echo "$line" | cut -d' ' -f1) 
   rest_of_line=$(echo "$line" | cut -d' ' -f2-)

   if [ "$first_field" = "#mtree" ]; then
       echo "$line"
       continue
   fi

   # Strip leading ./ prefix using parameter expansion
   first_field="${first_field/#.\//}"
   first_field="${first_field/#\//}"

   if [[ "$first_field" =~ ^control ]]; then
       first_field="./var/lib/dpkg/status.d/${package_name} contents=./${first_field}"
   elif [[ "$first_field" =~ ^md5sums ]]; then
       first_field="./var/lib/dpkg/status.d/${package_name}.md5sums contents=./${first_field}"
   fi

   if [ -n "$rest_of_line" ]; then
       echo "$first_field $rest_of_line"
   else
       echo "$first_field"
   fi
done | "$bsdtar" "$@" -cf "$out" -C "$tmp/" @-

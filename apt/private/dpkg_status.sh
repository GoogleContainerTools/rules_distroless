#!/usr/bin/env bash
set -o pipefail -o errexit -o nounset

readonly bsdtar="$1"
readonly coreutils="$2"
readonly out="$3"
shift 3

tmp_out=$($coreutils mktemp)

while  (( $# > 0 )); do
    $bsdtar -xf "$1" --to-stdout ./control | (
        # Print first line
        read -r line && echo "$line" && echo "Status: install ok installed"
        # Print remaining lines, including the last one
        while read -r line || [ -n "$line" ]; do
            echo "$line"
        done
        echo ""
    ) >> "$tmp_out"
    shift
done

echo "#mtree
./var/lib/dpkg/status type=file uid=0 gid=0 mode=0644 time=1672560000 contents=$tmp_out
" | "$bsdtar" "$@" -cf "$out" "@-"

$coreutils rm "$tmp_out"

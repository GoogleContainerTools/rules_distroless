#!/usr/bin/env bash
set -o pipefail -o errexit -o nounset

readonly bsdtar="$1"
readonly out="$2"
shift 2

tmp_out=$(mktemp)

while  (( $# > 0 )); do
    control="$($bsdtar -xf "$1" --to-stdout ./control)"
    echo "$control" | head -n 1 >> $tmp_out
    echo "Status: install ok installed" >> $tmp_out
    echo "$control" | tail -n +2 >> $tmp_out
    echo "" >> $tmp_out
    shift
done

mtree_out=$(mktemp)
echo "#mtree
./var/lib/dpkg/status type=file uid=0 gid=0 mode=0644 contents=$tmp_out
" > $mtree_out

"$bsdtar" $@ -cf "$out" "@$mtree_out"

rm $tmp_out $mtree_out
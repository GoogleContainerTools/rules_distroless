#!/usr/bin/env bash
set -o pipefail -o errexit -o nounset

readonly bsdtar="$1"
readonly out="$2"
shift 2

tmp_out=$(mktemp)

while  (( $# > 0 )); do
    $bsdtar -xf "$1" --to-stdout ./control |
    awk '{
        print $0; 
        if (NR == 1) { print "Status: install ok installed"};
    } END { print "" }
    ' >> $tmp_out
    shift
done

echo "#mtree
./var/lib/dpkg/status type=file uid=0 gid=0 time=0 mode=0644 contents=$tmp_out
" | "$bsdtar" $@ -cf "$out" "@-"

rm $tmp_out
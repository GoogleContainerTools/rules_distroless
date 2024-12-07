#!/usr/bin/env bash
set -o pipefail -o errexit

bsdtar="$1";
output="$2";
shift 2;

# Deduplication requested, use this complex pipeline to deduplicate.
if [[ "$output" != "-" ]]; then

    mtree=$(mktemp)

    # List files in all archives and append to single column mtree. 
    for arg in "$@"; do    
        if [[ "$arg" == "@"* ]]; then
            "$bsdtar" -tf "${arg:1}" >> "$mtree"
        fi
    done

    
    # There not a lot happening here but there is still too many implicit knowledge.
    # 
    # When we run bsdtar, we ask for it to prompt every entry, in the same order we created above, the mtree.
    # See: https://github.com/libarchive/libarchive/blob/f745a848d7a81758cd9fcd49d7fd45caeebe1c3d/tar/write.c#L683
    # 
    # For every prompt, therefore entry, we have write 31 bytes of data, one of which has to be either 'Y' or 'N'.
    # And the reason for it is that since we are not TTY and pretending to be one, we can't interleave write calls
    # so we have to interleave it by filling up the buffer with 31 bytes of 'Y' or 'N'.
    # See: https://github.com/libarchive/libarchive/blob/f745a848d7a81758cd9fcd49d7fd45caeebe1c3d/tar/util.c#L240
    # See: https://github.com/libarchive/libarchive/blob/f745a848d7a81758cd9fcd49d7fd45caeebe1c3d/tar/util.c#L216
    # 
    # And finally we iterate over all the entries generating 31 bytes of interleaved 'Y' or 'N' date based on if 
    # we came across the entry before, for directories the first occurrence is kept, and for files copies are 
    # preserved.
    $bsdtar --confirmation "$@" > $output 2< <(awk '{
        if (substr($0,0,1) == "#") {
            next;
        }
        count[$1]++;
        ORS=""
        keep="n"
        if (count[$1] == 1 || $1 !~ "/$") {
            keep="y"
        }
        for (i=0;i<31;i++) print keep
        fflush() 
    }' "$mtree")
    rm "$mtree"
else 
    # No deduplication, business as usual
    $bsdtar $@
fi
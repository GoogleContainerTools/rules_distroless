#!/usr/bin/env bash
set -o pipefail -o errexit

bsdtar="$1";
output="$2";
shift 2;

function run_gtar() {
    local TAR=
    if [[ "$(command -v gtar)" ]]; then
        TAR="gtar";
    elif [[ "$(command -v tar)" ]]; then
        TAR="tar";
    else
        echo "Neither 'tar' nor 'gtar' command is available.";
        exit 1;
    fi
    "$TAR" "$@";
}


# Deduplication requested, use this complex pipeline to deduplicate.
if [[ "$output" != "-" ]]; then

    mtree=$(mktemp)
    duplicates=$(mktemp)

    for arg in "$@"; do    
        if [[ "$arg" == "@"* ]]; then
            "$bsdtar" -cf - --format=mtree --options "mtree:!all,mtree:type" "$arg" >> "$mtree"
        fi
    done


    awk '{
        if (substr($0,0,1) == "#") {
            next;
        }
        line_count[$1]++;
        if (line_count[$1] > 1) {
            print substr($1, 3, length($1));
        }
    }' "$mtree" | sort | uniq | sort -r  > "$duplicates"
    $bsdtar $@ | run_gtar --delete --file - --occurrence=1 --files-from="$duplicates" > "$output"
    rm "$mtree"
else 
    # No deduplication, business as usual
    $bsdtar $@
fi
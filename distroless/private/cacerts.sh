#!/usr/bin/env bash
set -o pipefail -o errexit -o nounset

readonly bsdtar="$1"
readonly package_path="$2"
readonly cacerts_out="$3"
readonly copyright_out="$4"
readonly tmp="$(mktemp -d)"

"$bsdtar" -xf "$package_path" -C "$tmp" --strip-components 3 ./usr/share/ca-certificates ./usr/share/doc/ca-certificates/copyright

mv "$tmp/doc/ca-certificates/copyright" "$copyright_out"

function add_cert () {
    local dir="$1"
    for cert in $(ls -d -1 "$dir"/* | sort); do
        if [[ -d "$cert" ]]; then
            add_cert "$cert"
            continue
        fi
        cat $cert >> $cacerts_out
    done
}

add_cert "$tmp/ca-certificates"
rm -rf "$tmp"

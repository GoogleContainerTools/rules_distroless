#!/usr/bin/env bash
set -o pipefail -o errexit -o nounset

output=
while (( $# > 0 )); do
    case "${1}" in
        -o|--output) output="${2}"; shift 2
    esac
done

if [[ -z "$output" ]]; then 
    echo "-o|--output flag is required."
    exit 1
fi 

alias bsdtar="{{tar}}"
alias jq="{{jq}}"
readonly image="{{image}}"
readonly tags="{{tags}}"
readonly mtree="{{mtree}}"

readonly tree_relative_manifest_path=$(jq -r '.manifests[0].digest | sub(":"; "/")' "$image/index.json")

readonly manifest_path=$(mktemp)
readonly final_mtree_path=$(mktemp)

readonly jq_filter='.[0] |= {
    "Config": ( "blobs/" + ( $manifest[0].config.digest | sub(":"; "/") ) + ".tar.gz" ), 
    "RepoTags": $repotags | split("\n") | map(select(. != "")), 
    "Layers": $manifest[0].layers | map("blobs/" + . + ".tar.gz")
}'

jq -n "$jq_filter" > $manifest_path  \
   --slurpfile manifest "$image/blobs/$tree_relative_manifest_path" \
   --rawfile repotags $tags

cat $mtree > $final_mtree_path
echo "./manifest.json uid=0 gid=0 time=0 mode=0755 type=file content=$manifest_path" >> $final_mtree_path

bsdtar --create --file $output @$final_mtree_path
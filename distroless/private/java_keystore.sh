#!/usr/bin/env bash
set -o pipefail -o errexit -o nounset

readonly bsdtar="$1"
readonly keytool="$2"
readonly coreutils="$3"
readonly output="$4"
shift 4;

tmp=$(mktemp -d)
while (( $# > 0 )); do
    $coreutils csplit --quiet --elide-empty-files -f "$tmp/crt" -b "%02d_$#.crt" -k $1 '/-----BEGIN CERTIFICATE-----/' '{*}'
    shift;
done

for f in "$tmp"/*; do
    subject=$(openssl x509 -noout -subject -in $f | tr -d " ")
    $keytool -importcert -keystore $output -storepass changeit -file $f -alias "${subject#"subject="}" -noprompt
done
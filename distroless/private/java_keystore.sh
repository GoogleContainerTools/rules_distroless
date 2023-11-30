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

certs=$(echo "$tmp"/* | tr " " "\n" | sort -n | tr "\n" " ")

certopt="no_header,no_version,no_serial,no_signame,no_validity,no_issuer,no_pubkey,no_sigdump,no_aux,no_extensions"

for f in $certs; do
    subject=$(openssl x509 -in $f -noout -text -certopt $certopt | tr -d " " | tr -d '"')
    subject="${subject/#"Subject:"}" 
    echo "$subject"
    $keytool -importcert -keystore $output -storepass changeit -file $f -alias "${subject#"subject="}" -noprompt
done

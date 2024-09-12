#!/usr/bin/env bash
set -o pipefail -o errexit -o nounset

readonly bsdtar="$1"
readonly out="$2"
readonly control_path="$3"
readonly data_path="$4"
readonly package_name="$5"
shift 5

tmp=$(mktemp -d)
"$bsdtar" -xf "$control_path" -C "$tmp"

tmp2=$(mktemp -d)
"$bsdtar" -xf "$data_path" -C "$tmp2"

tmpfile=$(mktemp)
find "$tmp2" -type f | sed "s|^$tmp2/||" >> "$tmpfile"

# if the package is Multi-Arch: same, we need to append the architecture to the package name
control_file="$tmp/control"
package_name_with_arch=$(cat "$control_file" | while read -r line; do
  multi_arch_same=0
  arch=""
  while read -r line; do
    if [[ "$line" =~ ^Multi-Arch:\ same ]]; then
      multi_arch_same=1
    fi
    if [[ "$line" =~ ^Architecture: ]]; then
      arch=$(echo "$line" | cut -d' ' -f2)
    fi
  done < "$control_file"
  if [[ $multi_arch_same -eq 1 && -n $arch ]]; then
    echo "$package_name:$arch"
  else
    echo "$package_name"
  fi
done | tail -n1)

"$bsdtar" -cf - $@ --format=mtree --options '!gname,!uname,!sha1,!nlink,!time' "@$control_path" | \
awk -v pkg="$package_name_with_arch" -v tmpfile="$tmpfile" '{
    if ($1=="#mtree") {
        print $1; next
    };
    # strip leading ./ prefix
    sub(/^\.?\//, "", $1);
    if ($1==".") {
      next
    }
    if ($1 ~ /^control/) {
        $1 = "./var/lib/dpkg/info/" pkg ".list contents=" tmpfile;
    } else if ($1 ~ /^md5sums/) {
        $1 = "./var/lib/dpkg/info/" pkg ".md5sums contents=./" $1;
    } else {
        $1 = "./var/lib/dpkg/info/" pkg "." $1 " contents=./" $1;
    }
    print $0
}' | "$bsdtar" $@ -cf "$out" -C "$tmp/" @-
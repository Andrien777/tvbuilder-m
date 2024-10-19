#!/bin/sh
echo -ne '\033c\033]0;tvb2\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/tvb2-alpha-0.2.5.x86_64" "$@"

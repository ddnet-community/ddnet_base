#!/bin/bash

set -euo pipefail

log() {
	printf '[*] %s\n' "$1"
}

if [ ! -f scripts/update.sh ]; then
	echo "wrong working directory"
	exit 1
fi

if [ "$(basename "$PWD")" != ddnet_base ]; then
	echo "wrong working directory"
	exit 1
fi

if ! OLD_SRC="$(mktemp -d /tmp/old_src_XXXXX)"; then
	exit 1
fi

copy_code() {
	log "backing up old code to $OLD_SRC .."
	mv src/ "$OLD_SRC"

	mkdir -p src/ddnet_base
	cp -r ../ddnet/src/base src/ddnet_base

	mkdir -p src/ddnet_base/engine/external
	cp -r ../ddnet/src/engine/external/md5 src/ddnet_base/engine/external
	cp ../ddnet/src/engine/external/{.clang-tidy,.clang-format,important.txt} src/ddnet_base/engine/external
}

patch_includes() {
	while IFS= read -r -d '' header_file; do
		if [[ "$header_file" = src/ddnet_base/base/*/* ]]; then
			sed -E 's/^#include "..\/(.*)"/#include <ddnet_base\/base\/\1>/' "$header_file" > "$header_file".tmp
			mv "$header_file".tmp "$header_file"
		fi

		# TODO: merging into one sed command is probably faster
		sed -E 's/^#include "(.*)"/#include <ddnet_base\/base\/\1>/' "$header_file" |
			sed -E 's/^#include <base\/(.*)>/#include <ddnet_base\/base\/\1>/' > "$header_file".tmp
		mv "$header_file".tmp "$header_file"
	done < <(find src/ -name '*.h' -print0)
}

patch_namespace() {
	# we need to change md5 dependency from C to C++
	# so we can use the namespace feature
	# using C++ instead of C worked fine so far in https://github.com/ChillerDragon/antibob
	mv src/ddnet_base/engine/external/md5/md5.c src/ddnet_base/engine/external/md5/md5.cpp
	ruby scripts/namespaces.rb || exit 1
}

copy_code
patch_includes
patch_namespace
./scripts/fix_style.py

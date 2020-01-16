#!/bin/sh

fail() {
	printf "Err: %s\n" "$1"
	exit 1
}

mkdir -p ~/.config/
cat > ~/.config/fuckrc << EOF
# afuck env vars
AFUCK_TARGET_DIR=/sdcard/db

# ufuck env vars
UFUCK_TARGET_DIR=/mnt
EOF

cp bin/ufuck.sh /usr/bin/ufuck.sh || fail "Couldn't copy to /usr/bin"
cp bin/afuck.sh /usr/bin/afuck.sh || fail "Couldn't copy to /usr/bin"

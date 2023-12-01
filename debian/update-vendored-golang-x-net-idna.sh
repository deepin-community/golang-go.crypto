#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# This bash script downloads a vendored copy of golang.org/x/net/idna
# (using the specified golang.org/x/net version in go.mod)
# to avoid circular dependency between golang-golang-x-crypto-dev
# and golang-golang-x-net-dev.
#
# Copyright © 2020–2023 Anthony Fok <foka@debian.org>
# (Adapted from my personal sneak-in-go-package.sh script)

set -e

if ! grep ^XS-Go-Import-Path debian/control; then
	echo "Not in a Debian Go packaging directory."
	exit 1
fi

IMPORT_PATH="golang.org/x/net"
VERSION=$(grep golang.org/x/net go.mod | cut -d' ' -f2)

TEMPDIR=$(mktemp --dir --tmpdir sneak-XXXXXXXX)

echo "Running txtar-addmod $TEMPDIR $IMPORT_PATH@$VERSION ..."
# txtar-addmod -all $TEMPDIR $IMPORT_PATH@$VERSION
txtar-addmod "$TEMPDIR" $IMPORT_PATH@"$VERSION"

# Uppercase letters in txtar file names are changed into lowercase with an added "!" prefix
# shellcheck disable=SC2001
TXTAR_FILE=$TEMPDIR/$(echo "${IMPORT_PATH//\//_}" | sed -e 's/\([A-Z]\)/!\L\1/g')
TXTAR_FILE=$(echo "${TXTAR_FILE}"_*.txtar)

GOPATH=$(pwd)/debian/go
export GOPATH

if [ ! -f "$TXTAR_FILE" ]; then
	echo "$TXTAR_FILE not found!  Aborting..."
	exit 1
fi

ls -l "$TXTAR_FILE"
rm -rf "$GOPATH"/src/$IMPORT_PATH
txtar-x -C "$GOPATH"/src/$IMPORT_PATH "$TXTAR_FILE"
rm -f "$GOPATH"/src/$IMPORT_PATH/{.info,.mod}

# acme/autocert/autocert.go needs only golang.org/x/net/idna
find "$GOPATH"/src/$IMPORT_PATH -mindepth 1 -maxdepth 1 ! -name idna -exec rm -r '{}' \;

ls -lR debian/go/src/$IMPORT_PATH

rm -rf "$TEMPDIR"

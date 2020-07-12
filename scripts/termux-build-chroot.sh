#!/bin/bash

# Script for setting up a fake $PREFIX, on device, where packages can be
# installed without modifying our normal $PREFIX on device. The installed
# files can then be packaged into a .deb file. This script is just a simplified
# version of the termux-chroot script.

termux-build-chroot() {
	SCRIPTNAME=termux-build-chroot

	# For the /system/bin/linker(64) to be found:
	ARGS="-b /system:/system"

	# Bind $TERMUX_PKG_MASSAGEDIR/data to /data so that
	# `make install DESTDIR=/data/data/com.termux/files/usr/` installs to
	# this subdirectory in $TERMUX_PKG_MASSAGEDIR.
	ARGS="$ARGS -b $TERMUX_PKG_MASSAGEDIR/data:/data"

	# Android 10 needs /apex for /system/bin/linker:
	# https://github.com/termux/proot/issues/95#issuecomment-584779998
	if [ -d /apex ]; then
		ARGS="$ARGS -b /apex:/apex"
	fi

	# Keep home as it is. Packages shouldn't install files to it anyway
	ARGS="$ARGS -b $HOME:$HOME"

	# Mimic traditional Linux file system hierarchy - other Termux dirs:
	for f in bin etc lib share tmp var; do
		ARGS="$ARGS -b $PREFIX/$f:/$f"
	done

	# Mimic traditional Linux file system hierarchy- system dirs:
	for f in dev proc; do
		ARGS="$ARGS -b /$f:/$f"
	done

	# Root of the file system:
	ARGS="$ARGS -r $(realpath $PREFIX/..)"

	export PATH=/bin:$PATH
	export LD_LIBRARY_PATH=/lib
	# PROOT_NO_SECCOMP=1 is needed on some devices
	# export PROOT_NO_SECCOMP=1
	unset LD_PRELOAD

	proot $ARGS $@
}

# Make script standalone executable as well as sourceable
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	termux-build-chroot "$@"
fi

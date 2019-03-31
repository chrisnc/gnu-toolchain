#!/bin/bash

# Adapted from https://wiki.osdev.org/GCC_Cross-Compiler

topdir="$(pwd)"

target=arm-eabi
prefix="$topdir/dist/$target"
export PATH="$prefix/bin:$PATH"


# binutils

binutils_builddir="build/$target/binutils"
mkdir -p $binutils_builddir
pushd $binutils_builddir

"$topdir/binutils/configure" --target="$target" --prefix="$prefix" --with-sysroot --disable-nls --disable-werror
make --jobs $(nproc)
make install

popd

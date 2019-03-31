#!/bin/bash

set -xe

# Adapted from https://wiki.osdev.org/GCC_Cross-Compiler

topdir="$(pwd)"

target=arm-eabi
prefix="$topdir/dist/$target"
sysroot="$prefix/$target"
export PATH="$prefix/bin:$PATH"


# binutils

binutils_builddir="build/$target/binutils"
mkdir -p $binutils_builddir
pushd $binutils_builddir

export CC="gcc-8"
export CXX="g++-8"

"$topdir/binutils/configure" --target="$target" --prefix="$prefix" --with-sysroot="$sysroot" --disable-nls --disable-werror --enable-multilib --enable-ld=default --enable-gold=yes --enable-threads --enable-plugins

make --jobs $(nproc)
make install

popd

which -- "$target-as" || echo "$target-as" is not in the PATH


# gcc

gcc_builddir="build/$target/gcc"
mkdir -p $gcc_builddir
pushd $gcc_builddir

"$topdir/gcc/configure" --target="$target" --prefix="$prefix" --with-sysroot --with-newlib --disable-nls --enable-languages=c,c++
make --jobs $(nproc) all-gcc all-target-libgcc
make install-gcc install-target-libgcc

popd

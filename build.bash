#!/bin/bash

set -xe

# Adapted from https://wiki.osdev.org/GCC_Cross-Compiler

topdir="$(pwd)"

target=arm-eabi
prefix="$topdir/dist/$target"
sysroot="$prefix/$target"
export PATH="$prefix/bin:$PATH"

export CC="gcc-8"
export CXX="g++-8"

export CPPFLAGS="-I/usr/local/include"
export LDFLAGS="-L/usr/local/lib"


# binutils

binutils_builddir="$topdir/build/$target/binutils"
mkdir -p $binutils_builddir
pushd $binutils_builddir

"$topdir/binutils/configure" --quiet --target="$target" --prefix="$prefix" --with-sysroot="$sysroot" --disable-nls --disable-werror --enable-multilib --enable-ld=default --enable-gold=yes --enable-threads --enable-plugins

make --jobs $(nproc)
make install

popd

which -- "$target-as" || echo "$target-as" is not in the PATH


# first pass gcc

gcc1_builddir="$topdir/build/$target/gcc"
mkdir -p $gcc1_builddir
gcc1_distdir="$topdir/build/$target/gcc-dist"
mkdir -p $gcc1_distdir
pushd $gcc1_builddir

# first pass gcc config
"$topdir/gcc/configure" --target="$target" --prefix="$gcc1_distdir" --without-headers --enable-threads=no --disable-shared --enable-__cxa_atexit --disable-libgomp --disable-libmudflap --disable-libmpx --disable-libssp --disable-libquadmath --disable-libquadmath-support --disable-lto --enable-target-optspace --disable-nls --enable-multiarch --enable-languages=c

make --jobs $(nproc) all-gcc all-target-libgcc
make install-gcc install-target-libgcc

popd


# newlib

newlib_builddir="build/$target/newlib"
mkdir -p $newlib_builddir
pushd $newlib_builddir

NEWLIB_BUILD_PATH="$gcc1_distdir/bin:$prefix/bin:$sysroot/bin:$PATH"

PATH="$NEWLIB_BUILD_PATH" CFLAGS_FOR_TARGET="-mthumb-interwork -ffunction-sections -fdata-sections" "$topdir/newlib/configure" --target="$target" --prefix="$prefix" --enable-newlib-io-float --disable-newlib-io-long-double --enable-newlib-supplied-syscalls --disable-newlib-io-pos-args --enable-newlib-io-c99-formats --enable-newlib-io-long-long --disable-newlib-register-fini --disable-newlib-nano-malloc --disable-newlib-nano-formatted-io --disable-newlib-atexit-dynamic-alloc --enable-newlib-global-atexit --disable-lite-exit --enable-newlib-reent-small --enable-newlib-multithread --disable-newlib-wide-orient --disable-newlib-unbuf-stream-opt --enable-target-optspace

PATH="$NEWLIB_BUILD_PATH" make --jobs $(nproc)
make install

popd

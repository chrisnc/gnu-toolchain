#!/bin/bash

set -xe

# Adapted from https://wiki.osdev.org/GCC_Cross-Compiler

topdir="$(pwd)"

target=armeb-eabi
prefix="$topdir/dist/$target"
sysroot="$prefix/$target"
export PATH="$prefix/bin:$PATH"

# binutils

binutils_builddir="$topdir/build/$target/binutils"
mkdir -p $binutils_builddir
pushd $binutils_builddir

CXXFLAGS="-g -O2 -std=gnu++14" "$topdir/binutils/configure" --quiet --target="$target" --prefix="$prefix" --with-sysroot="$sysroot" --disable-nls --disable-werror --enable-ld=default --enable-gold=yes --enable-multilib --enable-plugins --enable-lto

make --jobs $(nproc)
make install

popd

which -- "$target-as" || echo "$target-as" is not in the PATH


# first pass gcc

core_gcc_builddir="$topdir/build/$target/core-gcc"
mkdir -p $core_gcc_builddir
core_gcc_distdir="$topdir/build/$target/core-gcc"
mkdir -p $core_gcc_distdir
pushd $core_gcc_builddir

"$topdir/gcc/configure" --quiet --target="$target" --prefix="$core_gcc_distdir" --without-headers --disable-shared --enable-__cxa_atexit --disable-libgomp --disable-libmudflap --disable-libmpx --disable-libssp --disable-libquadmath --disable-libquadmath-support --enable-target-optspace --disable-nls --disable-libstdc++-v3 --enable-multilib --enable-lto --enable-languages=c

make --jobs $(nproc) all-gcc all-target-libgcc
make install-gcc install-target-libgcc

popd


# newlib

newlib_builddir="build/$target/newlib"
mkdir -p $newlib_builddir
pushd $newlib_builddir

NEWLIB_BUILD_PATH="$core_gcc_distdir/bin:$sysroot/bin:$PATH"

PATH="$NEWLIB_BUILD_PATH" CFLAGS_FOR_TARGET="-ffunction-sections -fdata-sections" "$topdir/newlib/configure" --quiet --target="$target" --prefix="$prefix" --enable-ld=default --enable-gold=yes --enable-multilib --enable-newlib-io-float --disable-newlib-io-long-double --enable-newlib-supplied-syscalls --disable-newlib-io-pos-args --enable-newlib-io-c99-formats --enable-newlib-io-long-long --disable-newlib-register-fini --disable-newlib-nano-malloc --disable-newlib-nano-formatted-io --disable-newlib-atexit-dynamic-alloc --enable-newlib-global-atexit --disable-lite-exit --enable-newlib-reent-small --enable-newlib-multithread --disable-newlib-wide-orient --disable-newlib-unbuf-stream-opt --enable-target-optspace --enable-lto

PATH="$NEWLIB_BUILD_PATH" make --jobs $(nproc) &&
PATH="$NEWLIB_BUILD_PATH" make install

popd


# final gcc config

gcc_builddir="$topdir/build/$target/gcc"
mkdir -p $gcc_builddir
pushd $gcc_builddir

"$topdir/gcc/configure" --quiet --target="$target" --prefix="$prefix" --with-sysroot="$sysroot" --with-newlib --disable-shared --enable-__cxa_atexit --disable-libgomp --disable-libmudflap --disable-libmpx --disable-libssp --disable-libquadmath --disable-libquadmath-support --enable-target-optspace --enable-multilib --enable-lto --disable-nls --enable-languages=c,c++

make --jobs $(nproc)
make install

popd


# gcc config
#CPPFLAGS_FOR_TARGET="-idirafter $sysroot/include" LDFLAGS_FOR_TARGET="-static"
# --with-local-prefix="$sysroot"
#'--enable-threads=no'
#CFLAGS and CXXFLAGS -pipe
#LDFLAGS -static

# gdb config
#--with-build-sysroot
#'--includedir=/Users/chrisnc/projects/toolchain-armeb/armeb-eabi/armeb-eabi/include'
#'--with-python=/usr/bin/python2.7'
#'--disable-binutils'
#'--disable-ld'
#'--disable-gas'
#'--disable-threads'
#'--disable-nls'
#'--with-expat'
#'--without-libexpat-prefix'

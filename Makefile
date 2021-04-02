# Adapted from https://wiki.osdev.org/GCC_Cross-Compiler

topdir = $(shell pwd)
nproc = $(shell nproc)

prefix = $(topdir)/$(target)
sysroot = $(prefix)/$(target)

binutils_build = $(topdir)/build/$(target)/binutils
gcc_first_build = $(topdir)/build/$(target)/gcc_first
newlib_build = $(topdir)/build/$(target)/newlib
gcc_build = $(topdir)/build/$(target)/gcc

export PATH := $(prefix)/bin:$(PATH)

.PHONY: default
default: $(prefix)/bin/$(target)-gcc

UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
export CC := gcc-10
export CXX := g++-10
libprefix := /usr/local/opt
withlibflags := --with-mpfr=$(libprefix)/mpfr --with-mpc=$(libprefix)/libmpc --with-gmp=$(libprefix)/gmp
endif

# binutils

$(binutils_build)/Makefile: binutils
	mkdir -p $(binutils_build) && \
	cd $(binutils_build) && \
	"$(topdir)/binutils/configure" --quiet --target="$(target)" --prefix="$(prefix)" --with-sysroot="$(sysroot)" --disable-nls --disable-werror --disable-sim --disable-gdb --enable-ld=default --enable-gold=yes --enable-multilib --enable-plugins --enable-lto

$(prefix)/bin/$(target)-as: $(binutils_build)/Makefile
	cd "$(binutils_build)" && \
	make --jobs $(nproc) && \
	make install


# gcc (first pass, for building newlib)

$(gcc_first_build)/Makefile: gcc $(prefix)/bin/$(target)-as
	mkdir -p $(gcc_first_build) && \
	cd $(gcc_first_build) && \
	"$(topdir)/gcc/configure" --quiet --target="$(target)" --prefix="$(prefix)" --with-sysroot="$(sysroot)" --with-newlib --without-headers --disable-shared --enable-__cxa_atexit --disable-libgomp --disable-libmudflap --disable-libmpx --disable-libssp --disable-libquadmath --disable-libquadmath-support --disable-decimal-float --enable-target-optspace --disable-nls --disable-libstdc++-v3 --enable-multilib --enable-lto --enable-languages=c $(withlibflags)

$(gcc_first_build)/install.stmp: $(gcc_first_build)/Makefile
	cd $(gcc_first_build) && \
	make --jobs $(nproc) all-gcc all-target-libgcc && \
	make install-gcc install-target-libgcc && \
	touch install.stmp


# newlib

$(newlib_build)/Makefile: newlib $(gcc_first_build)/install.stmp
	mkdir -p $(newlib_build) && \
	cd $(newlib_build) && \
	"$(topdir)/newlib/configure" --quiet --target="$(target)" --prefix="$(prefix)" --enable-multilib --disable-newlib-supplied-syscalls --disable-newlib-io-pos-args --enable-newlib-io-c99-formats --enable-newlib-io-long-long --enable-newlib-retargetable-locking --enable-newlib-register-fini --disable-newlib-nano-malloc --disable-newlib-nano-formatted-io --disable-newlib-atexit-dynamic-alloc --enable-newlib-global-atexit --disable-lite-exit --enable-newlib-reent-small --enable-newlib-multithread --disable-newlib-wide-orient --disable-newlib-unbuf-stream-opt --enable-target-optspace --enable-lto

$(sysroot)/lib/libc.a: $(newlib_build)/Makefile
	cd "$(newlib_build)" && \
	make --jobs $(nproc) && \
	make install


# gcc (and libstdc++)

$(gcc_build)/Makefile: gcc $(sysroot)/lib/libc.a
	mkdir -p $(gcc_build) && \
	cd $(gcc_build) && \
	"$(topdir)/gcc/configure" --quiet --target="$(target)" --prefix="$(prefix)" --with-sysroot="$(sysroot)" --with-newlib --disable-shared --enable-__cxa_atexit --disable-libgomp --disable-libmudflap --disable-libmpx --disable-libssp --disable-libquadmath --disable-libquadmath-support --enable-target-optspace --enable-multilib --enable-lto --disable-nls --enable-languages=c $(withlibflags)

$(prefix)/bin/$(target)-gcc: $(gcc_build)/Makefile
	cd $(gcc_build) && \
	make --jobs $(nproc) && \
	make install

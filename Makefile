# Adapted from https://wiki.osdev.org/GCC_Cross-Compiler

topdir = $(shell pwd)
nproc = $(shell nproc)

target = arm-eabi
prefix = $(topdir)/$(target)
sysroot = $(prefix)/$(target)

binutils_build = $(topdir)/build/$(target)/binutils
gcc_first_build = $(topdir)/build/$(target)/gcc_first
newlib_build = $(topdir)/build/$(target)/newlib
gcc_build = $(topdir)/build/$(target)/gcc


.PHONY: default
default: $(prefix)/bin/$(target)-gcc

UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
export PATH := $(HOMEBREW_PREFIX)/opt/coreutils/libexec/gnubin:$(PATH)
export PATH := $(HOMEBREW_PREFIX)/opt/gnu-sed/libexec/gnubin:$(PATH)
export PATH := $(HOMEBREW_PREFIX)/opt/texinfo/bin:$(PATH)
export PATH := $(HOMEBREW_PREFIX)/opt/gcc/bin:$(PATH)
export CC := gcc-12
export CXX := g++-12
export CFLAGS := -I$(HOMEBREW_PREFIX)/include
export LDFLAGS := -L$(HOMEBREW_PREFIX)/lib
endif

export PATH := $(prefix)/bin:$(PATH)

# binutils

$(binutils_build)/Makefile: binutils
	mkdir -p $(binutils_build) && \
	cd $(binutils_build) && \
	"$(topdir)/binutils/configure" \
		--quiet \
		--target="$(target)" \
		--prefix="$(prefix)" \
		--with-sysroot="$(sysroot)" \
		--disable-nls \
		--disable-decimal-float \
		--disable-werror \
		--disable-sim \
		--enable-ld=yes \
		--enable-gold=default \
		--enable-multilib \
		--enable-plugins \
		--disable-gdb

$(prefix)/bin/$(target)-as: $(binutils_build)/Makefile
	cd "$(binutils_build)" && \
	make --jobs $(nproc) && \
	make install


# gcc (first pass, for building newlib)

$(gcc_first_build)/Makefile: gcc $(prefix)/bin/$(target)-as
	mkdir -p $(gcc_first_build) && \
	cd $(gcc_first_build) && \
	"$(topdir)/gcc/configure" \
		--quiet \
		--target="$(target)" \
		--prefix="$(prefix)" \
		--with-sysroot="$(sysroot)" \
		--with-newlib \
		--without-headers \
		--disable-shared \
		--enable-__cxa_atexit \
		--disable-libgomp \
		--disable-libmudflap \
		--disable-libmpx \
		--disable-libssp \
		--disable-libquadmath \
		--disable-libquadmath-support \
		--disable-decimal-float \
		--enable-target-optspace \
		--disable-nls \
		--enable-libstdc++-v3 \
		--enable-multilib \
		--enable-languages=c,c++

$(gcc_first_build)/install.stmp: $(gcc_first_build)/Makefile
	cd $(gcc_first_build) && \
	make --jobs $(nproc) all-gcc all-target-libgcc && \
	make install-gcc install-target-libgcc && \
	touch install.stmp


# newlib

$(newlib_build)/Makefile: newlib $(gcc_first_build)/install.stmp
	mkdir -p $(newlib_build) && \
	cd $(newlib_build) && \
	CFLAGS_FOR_TARGET="-ffunction-sections -fdata-sections -O3" \
		"$(topdir)/newlib/configure" \
		--quiet \
		--target="$(target)" \
		--prefix="$(prefix)" \
		--enable-multilib \
		--disable-newlib-io-pos-args \
		--enable-newlib-io-c99-formats \
		--enable-newlib-io-long-long \
		--enable-newlib-retargetable-locking \
		--enable-newlib-register-fini \
		--enable-newlib-nano-malloc \
		--enable-newlib-nano-formatted-io \
		--disable-newlib-atexit-dynamic-alloc \
		--enable-newlib-global-atexit \
		--enable-lite-exit \
		--enable-newlib-reent-small \
		--enable-newlib-multithread \
		--disable-newlib-wide-orient \
		--disable-newlib-unbuf-stream-opt \
		--enable-target-optspace \
		--enable-lto

$(sysroot)/lib/libc.a: $(newlib_build)/Makefile
	cd "$(newlib_build)" && \
	make --jobs $(nproc) && \
	make install


# final gcc

$(gcc_build)/Makefile: gcc $(sysroot)/lib/libc.a
	mkdir -p $(gcc_build) && \
	cd $(gcc_build) && \
	"$(topdir)/gcc/configure" \
		--quiet \
		--target="$(target)" \
		--prefix="$(prefix)" \
		--with-sysroot="$(sysroot)" \
		--with-newlib \
		--disable-shared \
		--enable-__cxa_atexit \
		--disable-libgomp \
		--disable-libmudflap \
		--disable-libmpx \
		--disable-libssp \
		--disable-libquadmath \
		--disable-libquadmath-support \
		--enable-target-optspace \
		--enable-multilib \
		--disable-nls \
		--enable-languages=c

$(prefix)/bin/$(target)-gcc: $(gcc_build)/Makefile
	cd $(gcc_build) && \
	make --jobs $(nproc) && \
	make install

# Makefile for building various dependencies
# Requires: git, cmake, ninja, wget, make, autoconf
# 
# Usage:
#   make          # Build all dependencies
#   make clean    # Clean build artifacts
#   make <lib>    # Build specific library (e.g., make dlib)

# Compiler and flags
CC      := gcc
CXX     := g++
CFLAGS  := -fPIC -m64
CXXFLAGS:= -fPIC -m64

# Installation directories
PREFIX     := $(CURDIR)/root
LIBDIR     := $(PREFIX)/usr/lib
INCLUDEDIR := $(PREFIX)/usr/include

.SHELLFLAGS := -e -c
SHELL := /bin/bash

# Common CMake flags
CMAKE_FLAGS := \
	-DCMAKE_INSTALL_PREFIX:PATH=$(PREFIX)/usr \
	-DCMAKE_INSTALL_LIBDIR:PATH=$(LIBDIR) \
	-DBUILD_SHARED_LIBS=OFF \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_POSITION_INDEPENDENT_CODE=ON \
	-DCMAKE_C_FLAGS="$(CFLAGS)" \
	-DCMAKE_CXX_FLAGS="$(CXXFLAGS)"

# Library versions and URLs
GCC_VERSION  := 14.2.0
ZLIB_VERSION := 1.3.1
GCC_URL      := https://github.com/gcc-mirror/gcc/archive/refs/tags/releases/gcc-$(GCC_VERSION).tar.gz
ZLIB_URL     := https://zlib.net/zlib-$(ZLIB_VERSION).tar.gz

# Directory structure
BUILD_DIR := build
DEPS_DIR  := deps
$(shell mkdir -p $(BUILD_DIR) $(DEPS_DIR))

# Library paths
DLIB_DIR   := $(DEPS_DIR)/dlib
LAPACK_DIR := $(DEPS_DIR)/lapack
JPEG_DIR   := $(DEPS_DIR)/libjpeg-turbo
GIF_DIR    := $(DEPS_DIR)/giflib
GCC_DIR    := $(DEPS_DIR)/gcc-releases-gcc-$(GCC_VERSION)
PNG_DIR    := $(DEPS_DIR)/libpng
ZLIB_DIR   := $(DEPS_DIR)/zlib

# Mark files for tracking cloned/downloaded repositories
CLONE_MARKERS := $(addsuffix /.cloned,$(DLIB_DIR) $(LAPACK_DIR) $(JPEG_DIR) $(GIF_DIR) $(PNG_DIR))
DOWNLOAD_MARKERS := $(addsuffix /.downloaded,$(GCC_DIR) $(ZLIB_DIR))

# Phony targets
.PHONY: all clean dlib lapack jpeg gif gcc png zlib

# Define build order - dlib needs all other libs except gcc
all: dlib lapack jpeg gif gcc png zlib

# Directory creation
$(PREFIX) $(LIBDIR) $(INCLUDEDIR):
	mkdir -p $@

# ZLIB (needs to be first as PNG depends on it)
$(ZLIB_DIR)/.downloaded:
	wget -O- $(ZLIB_URL) | tar xz -C $(DEPS_DIR)
	mv $(DEPS_DIR)/zlib-$(ZLIB_VERSION) $(ZLIB_DIR)
	touch $@

zlib: $(ZLIB_DIR)/.downloaded | $(PREFIX)
	cd $(ZLIB_DIR) && CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" ./configure --prefix=$(PREFIX)/usr \
		--libdir=$(LIBDIR) \
		--static
	$(MAKE) -C $(ZLIB_DIR)
	$(MAKE) -C $(ZLIB_DIR) install

# PNG (depends on ZLIB)
$(PNG_DIR)/.cloned:
	git clone https://github.com/pnggroup/libpng.git $(PNG_DIR)
	touch $@

png: zlib $(PNG_DIR)/.cloned | $(PREFIX)
	mkdir -p $(BUILD_DIR)/$@
	cd $(BUILD_DIR)/$@ && cmake $(CMAKE_FLAGS) \
		-DPNG_SHARED=OFF \
		-DPNG_STATIC=ON \
		-DPNG_TESTS=OFF \
		-DZLIB_ROOT=$(PREFIX)/usr \
		$(CURDIR)/$(PNG_DIR)
	$(MAKE) -C $(BUILD_DIR)/$@ && $(MAKE) -C $(BUILD_DIR)/$@ install

# JPEG
$(JPEG_DIR)/.cloned:
	git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git $(JPEG_DIR)
	touch $@

jpeg: $(JPEG_DIR)/.cloned | $(PREFIX)
	mkdir -p $(BUILD_DIR)/$@
	cd $(BUILD_DIR)/$@ && cmake $(CMAKE_FLAGS) \
		-DENABLE_SHARED=FALSE \
		-DENABLE_STATIC=TRUE \
		$(CURDIR)/$(JPEG_DIR)
	$(MAKE) -C $(BUILD_DIR)/$@ && $(MAKE) -C $(BUILD_DIR)/$@ install

# GIF
$(GIF_DIR)/.cloned:
	git clone https://github.com/mirrorer/giflib.git $(GIF_DIR)
	touch $@

gif: $(GIF_DIR)/.cloned | $(PREFIX)
	cd $(GIF_DIR) && autoreconf -i
	cd $(GIF_DIR) && CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" ./configure --prefix=$(PREFIX)/usr \
		--libdir=$(LIBDIR) \
		--disable-shared \
		--enable-static
	$(MAKE) -C $(GIF_DIR)
	$(MAKE) -C $(GIF_DIR) install

# LAPACK
$(LAPACK_DIR)/.cloned:
	git clone https://github.com/Reference-LAPACK/lapack $(LAPACK_DIR)
	touch $@

lapack: $(LAPACK_DIR)/.cloned | $(PREFIX)
	mkdir -p $(BUILD_DIR)/$@
	cd $(BUILD_DIR)/$@ && cmake $(CMAKE_FLAGS) \
		-DCBLAS=ON \
		$(CURDIR)/$(LAPACK_DIR)
	$(MAKE) -C $(BUILD_DIR)/$@ blas lapack cblas
	$(MAKE) -C $(BUILD_DIR)/$@ install

# DLIB - configured to use our custom built libraries
$(DLIB_DIR)/.cloned:
	git clone https://github.com/davisking/dlib.git $(DLIB_DIR)
	touch $@

dlib: jpeg png gif lapack $(DLIB_DIR)/.cloned | $(PREFIX)
	mkdir -p $(BUILD_DIR)/$@
	cd $(BUILD_DIR)/$@ && cmake $(CMAKE_FLAGS) \
		-GNinja \
		-DDLIB_USE_CUDA=OFF \
		-DDLIB_WEBP_SUPPORT=OFF \
		-DDLIB_JXL_SUPPORT=OFF \
		-DDLIB_PNG_SUPPORT=ON \
		-DDLIB_GIF_SUPPORT=ON \
		-DDLIB_JPEG_SUPPORT=ON \
		-DDLIB_USE_BLAS=ON \
		-DDLIB_USE_LAPACK=ON \
		-DDLIB_NO_GUI_SUPPORT=ON \
		-DPNG_LIBRARY=$(LIBDIR)/libpng.a \
		-DPNG_PNG_INCLUDE_DIR=$(INCLUDEDIR) \
		-DJPEG_LIBRARY=$(LIBDIR)/libjpeg.a \
		-DJPEG_INCLUDE_DIR=$(INCLUDEDIR) \
		-DGIF_LIBRARY=$(LIBDIR)/libgif.a \
		-DGIF_INCLUDE_DIR=$(INCLUDEDIR) \
		-DBLAS_LIBRARIES=$(LIBDIR)/libblas.a \
		-DLAPACK_LIBRARIES=$(LIBDIR)/liblapack.a \
		$(CURDIR)/$(DLIB_DIR)
	cd $(BUILD_DIR)/$@ && ninja && ninja install

# GCC (independent of other builds)
$(GCC_DIR)/.downloaded:
	wget -O- $(GCC_URL) | tar xz -C $(DEPS_DIR)
	touch $@

gcc: $(GCC_DIR)/.downloaded | $(PREFIX)
	cd $(GCC_DIR) && ./contrib/download_prerequisites
	mkdir -p $(BUILD_DIR)/$@
	cd $(BUILD_DIR)/$@ && CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" $(CURDIR)/$(GCC_DIR)/configure \
		--prefix=$(PREFIX)/usr \
		--libdir=$(LIBDIR) \
		--disable-shared \
		--enable-static \
		--enable-languages=fortran \
		--disable-multilib
	$(MAKE) -C $(BUILD_DIR)/$@
	$(MAKE) -C $(BUILD_DIR)/$@ install

# Clean all build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(PREFIX)

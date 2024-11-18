# Static DLIB Builder

A build system for creating fully static builds of DLIB and all its dependencies. This project enables the creation of portable, self-contained binaries that can run computer vision and machine learning applications without external library dependencies.

## Motivation

DLIB is a powerful C++ library for computer vision and machine learning, but deploying applications that use it can be challenging due to:
- Complex dependency chains
- Version compatibility issues
- System library inconsistencies
- Deployment environment variations

This build system solves these problems by:
- Building all dependencies from source
- Using static linking exclusively
- Creating self-contained binaries
- Eliminating runtime library dependencies
- Ensuring consistent behavior across systems

## What Gets Built

.
The build system compiles the following libraries statically:
- DLIB (main library)
- LAPACK/BLAS (linear algebra operations)
- JPEG (image support)
- PNG (image support)
- GIF (image support)
- GCC/gfortran runtime (for LAPACK/BLAS)
- ZLIB (compression support)

## Prerequisites

Required packages:
```bash

# Debian
apt-get install build-essential cmake ninja-build autoconf libtool pkg-config

# Arch
pacman -S base-devel cmake ninja autoconf libtool pkgconf
```

## Usage

1. Clone the repository:
```bash
git clone https://github.com/yourusername/static-dlib.git
cd static-dlib
```

2. Build everything:
```bash
make all
```

3. Find the static libraries in `root/usr/lib/`:
```bash
root/usr/lib/libdlib.a
root/usr/lib/libblas.a
root/usr/lib/liblapack.a
# etc...
```

## Using the Static Libraries

See the [examples](examples/) directory for detailed examples. Here's a basic usage:

```bash
gcc -O3 -static -o myapp myapp.c -I./root/usr/include \
    -L./root/usr/lib -L./root/usr/lib64 \
    -ldlib -lpthread -llapack -lcblas -lblas -ljpeg -lgif -lpng -lz -lgfortran 
```

## Configuration Options

The Makefile supports several options:
- `make clean` - Remove all built artifacts
- `make dlib` - Build only DLIB and its direct dependencies
- `make jpeg` - Build only JPEG library
- (etc...)

## Examples

The [examples](examples/) directory contains:
- Basic face detection
- Image processing
- Feature extraction
- And more...

## Contributing

Contributions are welcome! Please submit pull requests for:
- New examples
- Build improvements
- Documentation updates
- Bug fixes

## License

MIT License - See [LICENSE](LICENSE) for details

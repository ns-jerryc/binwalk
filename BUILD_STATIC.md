# Building Binwalk with Static Linking

This guide explains how to build binwalk as a statically-linked binary, which includes all dependencies and can run on any Linux system without requiring external libraries.

## Why Static Linking?

A statically-linked binary:
- **Portable**: Run on any Linux system without installing dependencies
- **Self-contained**: All libraries are embedded in the binary
- **Deployment-friendly**: Single file distribution
- **Version-locked**: No conflicts with system libraries

## Prerequisites

Choose one of these methods:

### Method 1: Native Build (Recommended)

**Requirements:**
- Rust toolchain (rustup recommended)
- musl-tools (for musl target)

**Install Rust:**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

**Install musl-tools (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install -y musl-tools
```

### Method 2: Docker Build (Easiest)

**Requirements:**
- Docker

**Install Docker:**
See https://docs.docker.com/get-docker/

## Building

### Method 1: Native Build

Simply run the build script:

```bash
./build_static.sh
```

This script will:
1. Check for required tools
2. Add the musl target (if using rustup)
3. Install musl-tools (if needed)
4. Build the static binary

The resulting binary will be at: `target/x86_64-unknown-linux-musl/release/binwalk`

### Method 2: Docker Build

Run the Docker build script:

```bash
./build_static_docker.sh
```

This uses a minimal Alpine Linux container to build the static binary without requiring Rust to be installed on your host system.

### Method 3: Manual Build

If you prefer manual control:

```bash
# Add the musl target
rustup target add x86_64-unknown-linux-musl

# Build with musl target
cargo build --release --target x86_64-unknown-linux-musl
```

The binary will be at: `target/x86_64-unknown-linux-musl/release/binwalk`

## Configuration

The repository includes a `.cargo/config.toml` file that automatically:
- Sets the default target to `x86_64-unknown-linux-musl`
- Enables `+crt-static` feature for full static linking

You can override this by building with a specific target:
```bash
cargo build --release --target x86_64-unknown-linux-gnu  # Dynamic linking
cargo build --release --target x86_64-unknown-linux-musl # Static linking
```

## Verifying Static Linking

Check that your binary is statically linked:

```bash
ldd target/x86_64-unknown-linux-musl/release/binwalk
```

**Expected output:**
- `not a dynamic executable` (fully static)
- or `statically linked` 

**If you see library dependencies**, the binary is dynamically linked.

## Troubleshooting

### Error: "cannot find -lmusl"

**Solution:** Install musl-tools:
```bash
sudo apt-get install musl-tools
```

### Error: "target 'x86_64-unknown-linux-musl' not found"

**Solution:** Add the target:
```bash
rustup target add x86_64-unknown-linux-musl
```

### Large Binary Size

Static binaries are larger because they include all dependencies. To reduce size:

```bash
# Build with size optimizations
cargo build --release --target x86_64-unknown-linux-musl
strip target/x86_64-unknown-linux-musl/release/binwalk

# Or use UPX compression (optional)
upx --best --lzma target/x86_64-unknown-linux-musl/release/binwalk
```

### Compilation Errors with musl

Some dependencies may have issues with musl. Common fixes:

1. **OpenSSL issues**: The project uses vendored OpenSSL via dependencies
2. **Missing symbols**: Ensure musl-dev is installed
3. **C library conflicts**: Use alpine-based Docker build instead

## Cross-Compilation

Build for other architectures:

```bash
# For ARM64
rustup target add aarch64-unknown-linux-musl
cargo build --release --target aarch64-unknown-linux-musl

# For ARM (32-bit)
rustup target add arm-unknown-linux-musleabi
cargo build --release --target arm-unknown-linux-musleabi
```

## Deployment

Copy the static binary anywhere:

```bash
cp target/x86_64-unknown-linux-musl/release/binwalk /usr/local/bin/
# or
./target/x86_64-unknown-linux-musl/release/binwalk --help
```

The binary requires no installation or dependencies!

## Performance

Static binaries may be slightly larger but typically have comparable or better performance than dynamically-linked binaries because:
- No dynamic linking overhead
- Better optimization opportunities
- Reduced memory fragmentation

## Additional Resources

- [Rust musl target documentation](https://doc.rust-lang.org/edition-guide/rust-2018/platform-and-target-support/musl-support-for-fully-static-binaries.html)
- [Cross-compilation guide](https://rust-lang.github.io/rustup/cross-compilation.html)

#!/usr/bin/env bash
set -e

# Script to build binwalk with static linking

echo "Building binwalk with static linking..."
echo ""

# Check if cargo is installed
if ! command -v cargo &> /dev/null; then
    echo "Error: Rust/Cargo is not installed."
    echo ""
    echo "Please install Rust using one of these methods:"
    echo "  1. Using rustup (recommended):"
    echo "     curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    echo "     source \$HOME/.cargo/env"
    echo ""
    echo "  2. Using your package manager:"
    echo "     sudo apt-get install cargo rustc"
    echo ""
    exit 1
fi

# Check if rustup is installed (optional but recommended)
if ! command -v rustup &> /dev/null; then
    echo "Warning: rustup is not installed. Using system Rust installation."
    echo "Note: You may need to manually add the musl target."
    echo ""
    RUSTUP_AVAILABLE=false
else
    RUSTUP_AVAILABLE=true
fi

# Install the musl target if rustup is available
if [ "$RUSTUP_AVAILABLE" = true ]; then
    echo "Ensuring musl target is installed..."
    rustup target add x86_64-unknown-linux-musl
else
    echo "Skipping rustup target installation (rustup not available)"
fi

# Install musl-tools if not already available (Debian/Ubuntu)
if command -v apt-get &> /dev/null; then
    if ! dpkg -l | grep -q musl-tools; then
        echo "Installing musl-tools..."
        sudo apt-get update
        sudo apt-get install -y musl-tools
    fi
fi

# Build with release profile and musl target
echo ""
echo "Building release binary with static linking..."
cargo build --release --target x86_64-unknown-linux-musl

echo ""
echo "Build complete!"
echo "Static binary located at: target/x86_64-unknown-linux-musl/release/binwalk"
echo ""

# Verify the binary
BINARY_PATH="target/x86_64-unknown-linux-musl/release/binwalk"
if [ -f "$BINARY_PATH" ]; then
    echo "Binary size: $(du -h "$BINARY_PATH" | cut -f1)"
    echo ""
    echo "Checking for dynamic dependencies:"
    ldd "$BINARY_PATH" || echo "✓ Binary is statically linked (no dynamic dependencies)"
fi

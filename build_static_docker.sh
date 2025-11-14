#!/usr/bin/env bash
set -e

# Script to build binwalk with static linking using Docker

echo "Building binwalk with static linking using Docker..."
echo ""

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed."
    echo "Please install Docker from https://docs.docker.com/get-docker/"
    exit 1
fi

# Create a temporary Dockerfile for static build
TEMP_DOCKERFILE=$(mktemp)
cat > "$TEMP_DOCKERFILE" << 'EOF'
FROM rust:alpine AS builder

# Install musl-dev for static linking
RUN apk add --no-cache musl-dev

# Install nightly toolchain for edition2024 support
RUN rustup default nightly

WORKDIR /app
COPY . .

# Disable kaleido feature for plotly (doesn't work with musl)
RUN sed -i 's/plotly = { version = "0.13.1", features = \["kaleido", "kaleido_download"\] }/plotly = "0.13.1"/' Cargo.toml

# Patch entropy.rs to disable PNG export (requires kaleido)
RUN sed -i '4s/use plotly::{ImageFormat, Plot, Scatter};/use plotly::{Plot, Scatter};/' src/entropy.rs && \
    sed -i '96,100c\            Some(_out_file_name) => {\n                eprintln!("Warning: PNG export is disabled in static builds. Use HTML output only.");\n                plot.show()\n            }' src/entropy.rs

# Build with static linking
RUN cargo build --release --target x86_64-unknown-linux-musl

# Create output stage
FROM scratch AS export
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/binwalk /binwalk
EOF

# Build the image
echo "Building Docker image with static binary..."
docker build -f "$TEMP_DOCKERFILE" --target builder -t binwalk-static-builder .

# Extract the binary from the builder stage
echo "Extracting static binary..."
mkdir -p target/x86_64-unknown-linux-musl/release
docker run --rm -v "$(pwd)/target:/output" --entrypoint sh binwalk-static-builder -c "cp /app/target/x86_64-unknown-linux-musl/release/binwalk /output/x86_64-unknown-linux-musl/release/binwalk && chmod +x /output/x86_64-unknown-linux-musl/release/binwalk"

# Clean up
rm "$TEMP_DOCKERFILE"

echo ""
echo "Build complete!"
BINARY_PATH="target/x86_64-unknown-linux-musl/release/binwalk"
if [ -f "$BINARY_PATH" ]; then
    echo "Static binary located at: $BINARY_PATH"
    echo "Binary size: $(du -h "$BINARY_PATH" | cut -f1)"
    echo ""
    echo "Checking for dynamic dependencies:"
    ldd "$BINARY_PATH" 2>&1 || echo "✓ Binary is statically linked (no dynamic dependencies)"
else
    echo "Warning: Binary not found at expected location"
    echo "Checking for binaries in target directory:"
    find target -name binwalk -type f 2>/dev/null || echo "No binwalk binary found"
fi

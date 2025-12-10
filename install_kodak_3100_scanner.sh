#!/bin/bash
set -e

# Variables
REPO_URL="https://github.com/rathodmanojkumar/Storage_Files/raw/main"
FILE="LinuxSoftware_s3000_v4.13.x86_64.deb.tar.gz"
DOWNLOAD_URL="${REPO_URL}/${FILE}"
WORKDIR="/tmp/kodak_scanner_$$"

echo "Creating working directory: $WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "Downloading scanner package..."
curl -L -o "$FILE" "$DOWNLOAD_URL"

echo "Extracting package..."
tar -xzf "$FILE"

# Find the extracted folder (first directory)
EXTRACT_DIR=$(find "$WORKDIR" -maxdepth 1 -type d ! -path "$WORKDIR" | head -n 1)

if [ -z "$EXTRACT_DIR" ]; then
    echo "Error: No directory found after extraction."
    exit 1
fi

echo "Entering extracted directory: $EXTRACT_DIR"
cd "$EXTRACT_DIR"

# Find setup file
SETUP_FILE=$(find . -maxdepth 2 -type f -iname "*setup*" | head -n 1)

if [ -z "$SETUP_FILE" ]; then
    echo "Error: Setup file not found."
    exit 1
fi

echo "Setup file found: $SETUP_FILE"
chmod +x "$SETUP_FILE"

echo "Running setup..."
sudo "$SETUP_FILE"

echo "Setup completed successfully!"
exit 0


#!/bin/bash

set -o pipefail # Check for errors in pipeline

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) # The full directory name of the script no matter where it is being called from
THIRD_PARTY_DIR="${SCRIPT_DIR}/../third_party"
AXI_DIR="axi"
if [ -z $OUTPUT_FILE_LOCATION ]; then
    OUTPUT_FILE_LOCATION="${SCRIPT_DIR}/axi.f"
fi
BENDER_URL="https://pulp-platform.github.io/bender/init"
BENDER_DIRECT_URL="https://github.com/pulp-platform/bender/releases/download/v0.29.0/bender-0.29.0-x86_64-linux-gnu.tar.gz"
if [ -z $BENDER_MANIFEST_DIR ]; then
    BENDER_MANIFEST_DIR="."
fi

pushd "$THIRD_PARTY_DIR"

echo "Updating the AXI submodule..."
git submodule update --init --recursive --remote "$AXI_DIR"

pushd "$AXI_DIR"

echo "Downloading and initializing Bender..."
if curl --proto '=https' --tlsv1.2 -sSf "$BENDER_URL" | bash; then
    echo "Bender installed successfully with automatic installation."
else
    echo "Automatic installation failed. Trying manual installation"

    if curl -L "$BENDER_DIRECT_URL" -o bender.tar.gz; then
        tar -xzf bender.tar.gz && rm -f bender.tar.gz
        echo "Manual installation completed."
    else
        echo "Failed to download Bender. Exiting..."
        exit 1
    fi
fi

echo "Generating the file list"

./bender update --dir $BENDER_MANIFEST_DIR
./bender script flist --dir $BENDER_MANIFEST_DIR > "$OUTPUT_FILE_LOCATION"

# Remove deprecated dependency since it causes errors
sed -i '/pad_functional.sv/d' "$OUTPUT_FILE_LOCATION"

git clean -dfx

popd
popd

echo "Generated flist for axi submodule"

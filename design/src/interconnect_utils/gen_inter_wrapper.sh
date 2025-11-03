#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) # The full directory name of the script no matter where it is being called from
THIRD_PARTY_DIR="${SCRIPT_DIR}/../../../third_party"
AXI_DIR="axi"
INTERCON_CONFIG="intercon_config.yaml"
OUTPUT_FILE_LOCATION="${SCRIPT_DIR}/../"
OUTPUT_FILE="axi_intercon.sv"

pushd "$THIRD_PARTY_DIR"

echo "Updating the AXI submodule..."
git submodule update --init --recursive --remote "$AXI_DIR"

pushd "$AXI_DIR/scripts"

echo "Generating the interconnect wrapper"
python3 axi_intercon_gen.py "${SCRIPT_DIR}/${INTERCON_CONFIG}"

echo "Moving the generated files to the tb/pulp_intercon directory"
mv ${OUTPUT_FILE} ${OUTPUT_FILE_LOCATION}

# Clean up the AXI directory
git clean -dfx

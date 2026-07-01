#!/bin/bash
# Install meshtastic-cli and pipx
#
# The rest of the script requires that meshtastic-cli is installed,
# so a "prerequisite" script should be run before all other steps.
#
# This uses pipx to avoid any issues with python environments
# and system packages

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Install meshtastic-cli"
echo "=========================================="
echo ""
echo "Reference: https://meshtastic.org/docs/software/python/cli/installation/"
echo ""

# Install pipx and all dependencies
echo "Installing pipx..."
sudo apt-get update
sudo apt-get install -y python3 pipx
pipx ensurepath
source ~/.bashrc

echo "Installing meshtastic-cli using pipx"
pipx install "meshtastic[cli]"
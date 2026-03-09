#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

sudo apt update
sudo apt install -y openocd
export OPENOCD_SCRIPTS=/usr/share/openocd/scripts
chmod +x SETUP_AND_FLASH.sh flash_ch32.sh
./SETUP_AND_FLASH.sh
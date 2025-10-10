#!/bin/bash

set -e

clear

TURQUOISE='\033[36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
echo -e "${YELLOW}Raindrops Uninstaller${NC}"
echo -e "${YELLOW}=====================${NC}"
echo -e "${TURQUOISE}by execRooted${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} This uninstaller must be run as root."
    exit 1
fi

if [ -f "/usr/local/bin/raindrops" ]; then
    echo -e "${YELLOW}[INFO]${NC} Removing raindrops from /usr/local/bin..."
    rm /usr/local/bin/raindrops
    echo -e "${TURQUOISE}[SUCCESS]${NC} Uninstallation complete!"
else
    echo -e "${YELLOW}[INFO]${NC} raindrops is not installed."
fi
#!/bin/bash

set -e

if [ -z "$TERM" ]; then
    export TERM=xterm
fi

clear

TURQUOISE='\033[36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

clear
echo -e "${BLUE}root_rain uninstaller${NC}"
echo -e "${BLUE}====================${NC}"
echo -e "${BLUE}by execRooted${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} This uninstaller must be run as root."
    echo -e "${YELLOW}[INFO]${NC} Please run: sudo $0"
    exit 1
fi

if [ -f "/usr/local/bin/root_rain" ]; then
    echo -e "${YELLOW}[INFO]${NC} Removing root_rain and rr from /usr/local/bin..."
    rm /usr/local/bin/root_rain
    rm -f /usr/local/bin/rr
    echo -e "${TURQUOISE}[SUCCESS]${NC} Uninstallation complete!"
else
    echo -e "${YELLOW}[INFO]${NC} root_rain is not installed."
fi


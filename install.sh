#!/bin/bash

set -e

if [ -z "$TERM" ]; then
    export TERM=xterm
fi

clear

TURQUOISE='\033[36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
echo -e "${YELLOW}Droplet Installer${NC}"
echo -e "${YELLOW}=================${NC}"
echo -e "${TURQUOISE}by execRooted${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} This installer must be run as root."
    echo -e "${YELLOW}[INFO]${NC} Please run: sudo $0"
    exit 1
fi

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    else
        echo "unknown"
    fi
}

install_build_deps() {
    local distro=$(detect_distro)
    echo -e "${YELLOW}[INFO]${NC} Detected distribution: $distro"
    case "$distro" in
        ubuntu|debian|linuxmint|pop)
            echo -e "${YELLOW}[INFO]${NC} Installing build dependencies for Debian/Ubuntu..."
            if ! apt update; then
                echo -e "${RED}[ERROR]${NC} Failed to update package list."
                exit 1
            fi
            if ! apt install -y build-essential pkg-config libssl-dev; then
                echo -e "${RED}[ERROR]${NC} Failed to install build dependencies."
                exit 1
            fi
            ;;
        arch|manjaro|endeavouros)
            echo -e "${YELLOW}[INFO]${NC} Installing build dependencies for Arch Linux..."
            if ! pacman -Syu --noconfirm base-devel pkg-config openssl; then
                echo -e "${RED}[ERROR]${NC} Failed to install build dependencies."
                exit 1
            fi
            ;;
        fedora)
            echo -e "${YELLOW}[INFO]${NC} Installing build dependencies for Fedora..."
            if ! dnf groupinstall -y "Development Tools"; then
                echo -e "${RED}[ERROR]${NC} Failed to install Development Tools."
                exit 1
            fi
            if ! dnf install -y pkg-config openssl-devel; then
                echo -e "${RED}[ERROR]${NC} Failed to install additional dependencies."
                exit 1
            fi
            ;;
        centos|rhel|almalinux|rocky)
            echo -e "${YELLOW}[INFO]${NC} Installing build dependencies for CentOS/RHEL..."
            if ! yum groupinstall -y "Development Tools"; then
                echo -e "${RED}[ERROR]${NC} Failed to install Development Tools."
                exit 1
            fi
            if ! yum install -y pkgconfig openssl-devel; then
                echo -e "${RED}[ERROR]${NC} Failed to install additional dependencies."
                exit 1
            fi
            ;;
        opensuse|sles)
            echo -e "${YELLOW}[INFO]${NC} Installing build dependencies for openSUSE..."
            if ! zypper install -y -t pattern devel_basis; then
                echo -e "${RED}[ERROR]${NC} Failed to install devel_basis pattern."
                exit 1
            fi
            if ! zypper install -y pkg-config libopenssl-devel; then
                echo -e "${RED}[ERROR]${NC} Failed to install additional dependencies."
                exit 1
            fi
            ;;
        *)
            echo -e "${YELLOW}[WARNING]${NC} Unknown distribution. Please install build tools manually (build-essential or equivalent, pkg-config, libssl-dev)."
            echo -e "${YELLOW}[INFO]${NC} Continuing with installation..."
            ;;
    esac
}

install_build_deps

install_rust() {
    local distro=$(detect_distro)
    echo -e "${YELLOW}[INFO]${NC} Installing Rust..."
    case "$distro" in
        ubuntu|debian|linuxmint|pop)
            if apt install -y rustc cargo; then
                echo -e "${TURQUOISE}[SUCCESS]${NC} Rust installed via apt."
                return 0
            else
                echo -e "${YELLOW}[INFO]${NC} apt installation failed, falling back to rustup."
            fi
            ;;
        arch|manjaro|endeavouros)
            if pacman -S --noconfirm rust; then
                echo -e "${TURQUOISE}[SUCCESS]${NC} Rust installed via pacman."
                return 0
            else
                echo -e "${YELLOW}[INFO]${NC} pacman installation failed, falling back to rustup."
            fi
            ;;
        fedora)
            if dnf install -y rust cargo; then
                echo -e "${TURQUOISE}[SUCCESS]${NC} Rust installed via dnf."
                return 0
            else
                echo -e "${YELLOW}[INFO]${NC} dnf installation failed, falling back to rustup."
            fi
            ;;
        centos|rhel|almalinux|rocky)
            if yum install -y rust cargo; then
                echo -e "${TURQUOISE}[SUCCESS]${NC} Rust installed via yum."
                return 0
            else
                echo -e "${YELLOW}[INFO]${NC} yum installation failed, falling back to rustup."
            fi
            ;;
        opensuse|sles)
            if zypper install -y rust cargo; then
                echo -e "${TURQUOISE}[SUCCESS]${NC} Rust installed via zypper."
                return 0
            else
                echo -e "${YELLOW}[INFO]${NC} zypper installation failed, falling back to rustup."
            fi
            ;;
    esac
    echo -e "${YELLOW}[INFO]${NC} Installing Rust via rustup..."
    if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
        echo -e "${RED}[ERROR]${NC} Failed to install Rust via rustup."
        exit 1
    fi
    export PATH="$HOME/.cargo/bin:$PATH"
}

if ! command -v cargo &> /dev/null; then
    install_rust
else
    echo -e "${YELLOW}[INFO]${NC} Rust is already installed."
fi

echo -e "${YELLOW}[INFO]${NC} Building droplet..."
if ! cargo build --release; then
    echo -e "${RED}[ERROR]${NC} Failed to build droplet."
    exit 1
fi

echo -e "${YELLOW}[INFO]${NC} Installing droplet to /usr/local/bin..."
if ! cp target/release/droplet /usr/local/bin/droplet; then
    echo -e "${RED}[ERROR]${NC} Failed to install droplet."
    exit 1
fi

if ! chmod +x /usr/bin/droplet; then
    echo -e "${RED}[ERROR]${NC} Failed to make droplet executable."
    exit 1
fi

echo -e "${TURQUOISE}[SUCCESS]${NC} Installation complete!"
echo -e "${YELLOW}[INFO]${NC} You can now run 'droplet' from anywhere."
echo -e "${YELLOW}[USAGE]${NC} To run the droplet animation, simply type: droplet"


#!/bin/bash

set -e

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
            apt update
            apt install -y build-essential pkg-config libssl-dev
            ;;
        arch|manjaro|endeavouros)
            echo -e "${YELLOW}[INFO]${NC} Installing build dependencies for Arch Linux..."
            pacman -Syu --noconfirm base-devel pkg-config openssl
            ;;
        fedora)
            echo -e "${YELLOW}[INFO]${NC} Installing build dependencies for Fedora..."
            dnf groupinstall -y "Development Tools"
            dnf install -y pkg-config openssl-devel
            ;;
        centos|rhel|almalinux|rocky)
            echo -e "${YELLOW}[INFO]${NC} Installing build dependencies for CentOS/RHEL..."
            yum groupinstall -y "Development Tools"
            yum install -y pkgconfig openssl-devel
            ;;
        opensuse|sles)
            echo -e "${YELLOW}[INFO]${NC} Installing build dependencies for openSUSE..."
            zypper install -y -t pattern devel_basis
            zypper install -y pkg-config libopenssl-devel
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
            fi
            ;;
        arch|manjaro|endeavouros)
            if pacman -S --noconfirm rust; then
                echo -e "${TURQUOISE}[SUCCESS]${NC} Rust installed via pacman."
                return 0
            fi
            ;;
        fedora)
            if dnf install -y rust cargo; then
                echo -e "${TURQUOISE}[SUCCESS]${NC} Rust installed via dnf."
                return 0
            fi
            ;;
        centos|rhel|almalinux|rocky)
            if yum install -y rust cargo; then
                echo -e "${TURQUOISE}[SUCCESS]${NC} Rust installed via yum."
                return 0
            fi
            ;;
        opensuse|sles)
            if zypper install -y rust cargo; then
                echo -e "${TURQUOISE}[SUCCESS]${NC} Rust installed via zypper."
                return 0
            fi
            ;;
    esac
    echo -e "${YELLOW}[INFO]${NC} Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    export PATH="$HOME/.cargo/bin:$PATH"
}

if ! command -v cargo &> /dev/null; then
    install_rust
else
    echo -e "${YELLOW}[INFO]${NC} Rust is already installed."
fi

echo -e "${YELLOW}[INFO]${NC} Building droplet..."
cargo build --release

echo -e "${YELLOW}[INFO]${NC} Installing droplet to /usr/local/bin..."
cp target/release/droplet /usr/local/bin/droplet

chmod +x /usr/local/bin/droplet

echo -e "${TURQUOISE}[SUCCESS]${NC} Installation complete!"
echo -e "${YELLOW}[INFO]${NC} You can now run 'droplet' from anywhere."
echo -e "${YELLOW}[USAGE]${NC} To run the droplet animation, simply type: droplet"
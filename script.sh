#!/bin/bash

# XMRig Miner Installation and Execution Script
# Description: Downloads and runs XMRig miner for Unmineable pool
# Warning: Ensure you have permission to run mining software on this system

set -euo pipefail

# Configuration variables
VERSION="6.21.0"
ARCH="linux-static-x64"
TAR_FILE="xmrig-${VERSION}-${ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/xmrig/xmrig/releases/download/v${VERSION}/${TAR_FILE}"
INSTALL_DIR="xmrig-${VERSION}"
POOL_URL="rx.unmineable.com:3333"
WALLET_ADDRESS="IRON:13e676097b639aad6f785eb03369dee66d5d83b5be074b591931a096db9ecfa6.paid"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        warning "Running as root is not recommended for security reasons"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Check dependencies
check_dependencies() {
    local deps=("curl" "tar")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "$dep is required but not installed. Please install it first."
        fi
    done
}

# Download and extract XMRig
download_xmrig() {
    log "Downloading XMRig ${VERSION}..."
    if curl -s -L "$DOWNLOAD_URL" | tar -xz; then
        log "Download and extraction completed successfully"
    else
        error "Failed to download or extract XMRig"
    fi
}

# Verify XMRig binary
verify_binary() {
    if [ ! -f "${INSTALL_DIR}/xmrig" ]; then
        error "XMRig binary not found in ${INSTALL_DIR}"
    fi
    
    if [ ! -x "${INSTALL_DIR}/xmrig" ]; then
        chmod +x "${INSTALL_DIR}/xmrig"
        log "Made XMRig binary executable"
    fi
}

# Run XMRig miner
run_miner() {
    log "Starting XMRig miner..."
    log "Pool: ${POOL_URL}"
    log "Wallet: ${WALLET_ADDRESS}"
    log "Press Ctrl+C to stop mining"
    echo
    
    cd "$INSTALL_DIR" || error "Failed to enter XMRig directory"
    
    # Run XMRig with the specified configuration
    ./xmrig -o "$POOL_URL" -u "$WALLET_ADDRESS"
}

# Cleanup function
cleanup() {
    log "Cleaning up..."
    # Add any cleanup tasks here if needed
}

# Main execution
main() {
    echo "=========================================="
    echo "    XMRig Miner Script"
    echo "    Version: ${VERSION}"
    echo "=========================================="
    echo
    
    warning "Please ensure you have permission to run mining software on this system"
    warning "Mining may impact system performance and increase electricity costs"
    echo
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Operation cancelled by user"
        exit 0
    fi
    
    check_root
    check_dependencies
    download_xmrig
    verify_binary
    run_miner
}

# Set up trap for cleanup
trap cleanup EXIT
trap 'error "Script interrupted by user"; exit 1' INT TERM

# Run main function
main "$@"

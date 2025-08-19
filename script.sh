#!/bin/bash

# XMRig Miner - Optimized for AMD EPYC
# Description: High-performance mining configuration for AMD EPYC processors

set -euo pipefail

# Configuration
VERSION="6.21.0"
ARCH="linux-static-x64"
TAR_FILE="xmrig-${VERSION}-${ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/xmrig/xmrig/releases/download/v${VERSION}/${TAR_FILE}"
INSTALL_DIR="xmrig-${VERSION}"
POOL_URL="rx.unmineable.com:3333"
WALLET_ADDRESS="IRON:13e676097b639aad6f785eb03369dee66d5d83b5be074b591931a096db9ecfa6.paid"

# Performance tuning - Adjust based on your EPYC model
THREADS=$(nproc)  # Use all available threads
HUGE_PAGES="true"
CPU_AFFINITY="true"
CPU_PRIORITY="0"  # Higher priority (may require root)
DONATE_LEVEL="0"  # 0% donation to XMRig devs
ALGO="rx/0"       # RandomX algorithm

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# System information
get_system_info() {
    info "System Information:"
    info "CPU: $(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^ *//')"
    info "Cores: $(nproc)"
    info "Memory: $(free -h | awk '/Mem:/ {print $2}')"
    info "Kernel: $(uname -r)"
    echo
}

# Check and configure huge pages
configure_hugepages() {
    if [ "$HUGE_PAGES" = "true" ]; then
        info "Configuring huge pages for better performance..."
        
        # Check current huge pages
        CURRENT_PAGES=$(cat /proc/sys/vm/nr_hugepages 2>/dev/null || echo "0")
        
        # Calculate recommended huge pages (approx 2GB per NUMA node for RandomX)
        RECOMMENDED_PAGES=512
        
        if [ "$CURRENT_PAGES" -lt "$RECOMMENDED_PAGES" ]; then
            warning "Current huge pages: $CURRENT_PAGES (recommended: $RECOMMENDED_PAGES)"
            
            if [ "$EUID" -eq 0 ]; then
                echo "$RECOMMENDED_PAGES" > /proc/sys/vm/nr_hugepages
                log "Huge pages configured to: $RECOMMENDED_PAGES"
            else
                warning "Run as root to configure huge pages automatically"
                warning "Or run manually: echo $RECOMMENDED_PAGES | sudo tee /proc/sys/vm/nr_hugepages"
            fi
        else
            log "Huge pages already configured: $CURRENT_PAGES"
        fi
    fi
}

# CPU optimization
optimize_cpu() {
    info "Applying CPU optimizations..."
    
    # Disable CPU frequency scaling for better performance
    if command -v cpupower &> /dev/null && [ "$EUID" -eq 0 ]; then
        cpupower frequency-set --governor performance
        log "CPU governor set to performance mode"
    fi
    
    # Check for AMD specific optimizations
    if grep -q "AMD" /proc/cpuinfo; then
        log "AMD processor detected - applying optimizations"
    fi
}

# Download and setup XMRig
setup_xmrig() {
    if [ ! -d "$INSTALL_DIR" ]; then
        log "Downloading XMRig ${VERSION}..."
        curl -s -L "$DOWNLOAD_URL" | tar -xz
    fi
    
    if [ ! -f "${INSTALL_DIR}/xmrig" ]; then
        error "XMRig binary not found"
    fi
    
    chmod +x "${INSTALL_DIR}/xmrig"
}

# Generate config.json for better control
generate_config() {
    local config_file="${INSTALL_DIR}/config.json"
    
    cat > "$config_file" << EOF
{
    "autosave": true,
    "cpu": {
        "enabled": true,
        "huge-pages": $HUGE_PAGES,
        "hw-aes": null,
        "priority": $CPU_PRIORITY,
        "memory-pool": true,
        "asm": true,
        "argon2-impl": null,
        "astrobwt-max-size": 550,
        "astrobwt-avx2": false,
        "argon2": [0, 1, 2, 3],
        "astrobwt": [0, 1, 2, 3],
        "cn": [
            [1, 0],
            [1, 2],
            [1, 3]
        ],
        "cn-heavy": [
            [1, 0],
            [1, 2],
            [1, 3]
        ],
        "cn-lite": [
            [1, 0],
            [1, 2],
            [1, 3]
        ],
        "cn-pico": [
            [2, 0],
            [2, 2],
            [2, 3]
        ],
        "cn/upx2": [
            [2, 0],
            [2, 2],
            [2, 3]
        ],
        "ghostrider": [
            [8, 0],
            [8, 2],
            [8, 3]
        ],
        "rx": [0, 2],
        "rx/wow": [0, 2],
        "rx/arq": [0, 2],
        "rx/keva": [0, 2],
        "rx/0": [0, 2],
        "argon2/chukwav2": [0, 2]
    },
    "opencl": false,
    "cuda": false,
    "donate-level": $DONATE_LEVEL,
    "log-file": null,
    "pools": [
        {
            "algo": "$ALGO",
            "coin": null,
            "url": "$POOL_URL",
            "user": "$WALLET_ADDRESS",
            "pass": "x",
            "rig-id": null,
            "nicehash": false,
            "keepalive": true,
            "enabled": true,
            "tls": false,
            "tls-fingerprint": null,
            "daemon": false,
            "socks5": null,
            "self-select": null,
            "submit-to-origin": false
        }
    ],
    "print-time": 60,
    "health-print-time": 60,
    "retries": 5,
    "retry-pause": 5,
    "syslog": false,
    "tls": {
        "enabled": false,
        "protocols": null,
        "cert": null,
        "cert_key": null,
        "ciphers": null,
        "ciphersuites": null,
        "dhparam": null
    },
    "user-agent": null,
    "verbose": 0,
    "watch": true,
    "pause-on-battery": false,
    "pause-on-active": false
}
EOF
    
    log "Generated optimized config.json"
}

# Run XMRig with optimized parameters
run_optimized() {
    cd "$INSTALL_DIR" || error "Cannot enter XMRig directory"
    
    info "Starting XMRig with optimized settings..."
    info "Threads: $THREADS"
    info "Algorithm: $ALGO"
    info "Pool: $POOL_URL"
    echo
    
    # Run with optimized parameters
    ./xmrig --config=config.json \
        --threads=$THREADS \
        --cpu-affinity=$CPU_AFFINITY \
        --cpu-priority=$CPU_PRIORITY \
        --randomx-init=$THREADS \
        --randomx-mode=fast \
        --verbose
}

# Main execution
main() {
    echo "================================================"
    echo "   XMRig Miner - AMD EPYC Optimized"
    echo "   Version: ${VERSION}"
    echo "================================================"
    echo
    
    get_system_info
    
    warning "Performance mining script - Ensure proper cooling and power capacity!"
    read -p "Continue with optimizations? (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || exit 0
    
    configure_hugepages
    optimize_cpu
    setup_xmrig
    generate_config
    run_optimized
}

# Cleanup and error handling
trap 'echo; log "Script interrupted"; exit 1' INT TERM
trap 'echo; log "Cleaning up..."' EXIT

main "$@"

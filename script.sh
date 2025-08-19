#!/bin/bash

# Simple XMRig Runner Script
# Runs the exact command as provided

curl -s -L https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-static-x64.tar.gz | tar -xz && cd xmrig-6.21.0 && ./xmrig -o rx.unmineable.com:3333 -u IRON:13e676097b639aad6f785eb03369dee66d5d83b5be074b591931a096db9ecfa6.paid

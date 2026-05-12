#!/bin/bash

#===================================================================================
# Show Docker Credentials Helper Keys & Status
# Run this script anytime to view your GPG keys and Docker credentials configuration
#===================================================================================

set -e

# Colors for output
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

main() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Docker Credentials Helper - Keys & Status                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # 1. Display GPG Keys
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  1. GPG KEYS${NC}"
    echo -e "${BLUE}========================================${NC}"
    gpg --list-secret-keys --keyid-format LONG
    
    # 2. Display GPG Key Details
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  2. GPG KEY DETAILS${NC}"
    echo -e "${BLUE}========================================${NC}"
    gpg --list-secret-keys --keyid-format LONG | grep -A1 "sec" || log_warning "No keys found"
    
    # 3. Display Pass Configuration
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  3. PASS STORE CONFIGURATION${NC}"
    echo -e "${BLUE}========================================${NC}"
    if [ -d "$HOME/.password-store" ]; then
        log_success "Pass store initialized at: $HOME/.password-store"
        echo ""
        echo "Pass store contents:"
        pass ls 2>/dev/null || echo "  (empty)"
    else
        log_error "Pass store not found at: $HOME/.password-store"
    fi
    
    # 4. Display Docker Config
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  4. DOCKER CONFIGURATION${NC}"
    echo -e "${BLUE}========================================${NC}"
    if [ -f "$HOME/.docker/config.json" ]; then
        log_success "Docker config found at: $HOME/.docker/config.json"
        echo ""
        cat "$HOME/.docker/config.json"
    else
        log_error "Docker config not found"
    fi
    
    # 5. Display Docker Credentials Helper Status
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  5. DOCKER CREDENTIALS STORED${NC}"
    echo -e "${BLUE}========================================${NC}"
    if command -v docker-credential-pass &> /dev/null; then
        CREDS=$(docker-credential-pass list 2>/dev/null || echo "")
        if [ -z "$CREDS" ]; then
            log_warning "No Docker credentials stored yet"
            echo "Run 'docker login' to add credentials"
        else
            echo "$CREDS" | jq . 2>/dev/null || echo "$CREDS"
        fi
    else
        log_error "docker-credential-pass not found"
    fi
    
    # 6. Verify Docker integration
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  6. CREDENTIAL HELPER STATUS${NC}"
    echo -e "${BLUE}========================================${NC}"
    docker-credential-pass --version 2>/dev/null && \
        log_success "docker-credential-pass is available" || \
        log_error "docker-credential-pass not found"
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
}

main "$@"

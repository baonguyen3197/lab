#!/bin/bash

#===================================================================================
# Docker Credentials Helper Installation & Configuration Script
# This script automates the installation and configuration of docker-credential-pass
# with GPG key generation for secure Docker credential storage
#===================================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

#===================================================================================
# 1. INSTALL DEPENDENCIES
#===================================================================================
install_dependencies() {
    log_info "Installing dependencies..."
    
    # Update package manager
    sudo apt update
    
    # Install Java
    log_info "Installing Java (OpenJDK 21)..."
    sudo apt install -y openjdk-21-jre-headless
    
    # Install docker-credential-helpers
    log_info "Installing docker-credential-helpers..."
    sudo apt install -y golang-docker-credential-helpers
    
    # Install pass (password manager)
    log_info "Installing pass..."
    sudo apt install -y pass
    
    # Verify installations
    log_info "Verifying installations..."
    java -version 2>&1 | head -1
    docker-credential-pass --version 2>/dev/null || log_warning "docker-credential-pass verification skipped"
    pass --version || log_warning "pass verification skipped"
    
    log_success "All dependencies installed successfully"
}

#===================================================================================
# 2. GENERATE GPG KEY
#===================================================================================
generate_gpg_key() {
    log_info "Generating GPG key..."
    
    # Check if GPG key already exists
    EXISTING_KEYS=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -c "sec" || true)
    
    if [ "$EXISTING_KEYS" -gt 0 ]; then
        log_warning "GPG keys already exist. Using existing key."
        return
    fi
    
    # Generate GPG key with batch mode
    # Note: This creates a key with default settings
    log_info "Creating GPG key batch configuration..."
    
    # Generate a new GPG key
    gpg --batch --generate-key <<EOF
Key-Type: default
Key-Length: 4096
Name-Real: Docker Credentials
Name-Email: docker-credentials@local
Passphrase:
%no-protection
EOF
    
    log_success "GPG key generated successfully"
}

#===================================================================================
# 3. GET GPG KEY ID
#===================================================================================
get_gpg_key_id() {
    log_info "Retrieving GPG key ID..."
    
    # Get the key ID (first key, long format)
    GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | \
                 grep "sec" | head -1 | awk '{print $2}' | cut -d'/' -f2)
    
    if [ -z "$GPG_KEY_ID" ]; then
        log_error "Failed to retrieve GPG key ID"
        exit 1
    fi
    
    echo "$GPG_KEY_ID"
}

#===================================================================================
# 4. INITIALIZE PASS
#===================================================================================
init_pass() {
    local GPG_KEY_ID=$1
    log_info "Initializing pass with GPG key ID: $GPG_KEY_ID..."
    
    # Check if pass is already initialized
    if [ -d "$HOME/.password-store" ]; then
        log_warning "Pass already initialized. Skipping..."
        return
    fi
    
    # Initialize pass with the GPG key
    pass init "$GPG_KEY_ID" 2>/dev/null || true
    
    log_success "Pass initialized successfully"
}

#===================================================================================
# 5. CONFIGURE DOCKER
#===================================================================================
configure_docker() {
    log_info "Configuring Docker to use credential helper..."
    
    # Create Docker config directory if it doesn't exist
    mkdir -p "$HOME/.docker"
    
    # Create Docker config with credential helper
    cat > "$HOME/.docker/config.json" <<EOF
{
    "auths": {},
    "credsStore": "pass"
}
EOF
    
    log_success "Docker configured with credential helper (pass)"
}

#===================================================================================
# 6. SHOW GENERATED KEYS
#===================================================================================
show_keys() {
    log_info "Displaying generated keys and configuration..."
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  GPG KEYS${NC}"
    echo -e "${BLUE}========================================${NC}"
    gpg --list-secret-keys --keyid-format LONG
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  PASS CONFIGURATION${NC}"
    echo -e "${BLUE}========================================${NC}"
    if [ -d "$HOME/.password-store" ]; then
        pass ls || log_warning "Pass store appears empty"
    else
        log_warning "Pass store not initialized"
    fi
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  DOCKER CONFIG${NC}"
    echo -e "${BLUE}========================================${NC}"
    cat "$HOME/.docker/config.json" | head -20
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  DOCKER CREDENTIALS HELPER STATUS${NC}"
    echo -e "${BLUE}========================================${NC}"
    docker-credential-pass list 2>/dev/null || echo "No credentials stored yet"
    
    echo ""
}

#===================================================================================
# MAIN EXECUTION
#===================================================================================
main() {
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Docker Credentials Helper Installation & Configuration    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if running on Linux
    if [[ ! "$OSTYPE" =~ ^linux ]]; then
        log_error "This script is designed for Linux systems only"
        exit 1
    fi
    
    # Run installation steps
    install_dependencies
    echo ""
    
    generate_gpg_key
    echo ""
    
    GPG_KEY_ID=$(get_gpg_key_id)
    log_success "GPG Key ID: $GPG_KEY_ID"
    echo ""
    
    init_pass "$GPG_KEY_ID"
    echo ""
    
    configure_docker
    echo ""
    
    show_keys
    
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Installation completed successfully!                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}NEXT STEPS:${NC}"
    echo "1. Logout and login again to apply changes"
    echo "2. Run: docker login"
    echo "3. Verify: docker-credential-pass list"
    echo "4. Use: docker push/pull without credential wrapping in Jenkins"
    echo ""
}

# Run main function
main "$@"

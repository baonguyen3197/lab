#!/bin/bash

#===================================================================================
# Docker Credentials Helper Installation & Configuration Script
# This script automates the installation and configuration of docker-credential-pass
# with GPG key generation for secure Docker credential storage in a persistent directory
#===================================================================================

set -e

# Set default values for credentials directory and GPG identity
CREDS_DIR="."
GPG_REAL_NAME="nhqb3197"
GPG_EMAIL="baonguyen3197@gmail.com"

#===================================================================================
# PARSE COMMAND LINE ARGUMENTS
#===================================================================================
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--username)
                GPG_REAL_NAME="$2"
                shift 2
                ;;
            -e|--email)
                GPG_EMAIL="$2"
                shift 2
                ;;
            -d|--dir)
                CREDS_DIR="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << 'EOF'
Docker Credentials Helper Installation Script

Usage: bash install-docker-credentials.sh [OPTIONS]

Options:
  -u, --username USER   GPG key username/real name
  -e, --email EMAIL     GPG key email address
  -d, --dir DIR         Credentials directory (default: current directory)
  -h, --help            Show this help message

Examples:
  bash install-docker-credentials.sh
  bash install-docker-credentials.sh -u john -e john@example.com
  bash install-docker-credentials.sh -u "John Doe" -e john@example.com -d /home/john
EOF
}

export GNUPGHOME="${CREDS_DIR}/.gnupg"
PASS_STORE_DIR="${CREDS_DIR}/.password-store"
DOCKER_CONFIG_DIR="${CREDS_DIR}/.docker"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
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
    if command -v docker-credential-pass >/dev/null 2>&1; then
        log_info "docker-credential-pass found: $(command -v docker-credential-pass)"
    else
        log_warning "docker-credential-pass not found in PATH"
    fi
    pass --version || log_warning "pass verification skipped"
    
    log_success "All dependencies installed successfully"
}

#===================================================================================
# 2. GENERATE GPG KEY
#===================================================================================
generate_gpg_key() {
    log_info "Generating GPG key in: $GNUPGHOME"
    log_info "GPG identity: $GPG_REAL_NAME <$GPG_EMAIL>"
    
    # Create GPG home directory if it doesn't exist
    mkdir -p "$GNUPGHOME"
    chmod 700 "$GNUPGHOME"
    
    # Check if GPG key already exists
    EXISTING_KEYS=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -c "sec" || true)
    
    if [ "$EXISTING_KEYS" -gt 0 ]; then
        log_warning "GPG keys already exist at $GNUPGHOME. Using existing key."
        return
    fi
    
    # Generate GPG key with batch mode
    # Creates EdDSA (ed25519) key with ECDH (cv25519) encryption subkey
    log_info "Creating GPG key batch configuration..."

    # Generate the key and capture any output for debugging
    GPG_OUTPUT=$(gpg --batch --generate-key <<EOF 2>&1
Key-Type: eddsa
Key-Curve: ed25519
Subkey-Type: ecdh
Subkey-Curve: cv25519
Name-Real: $GPG_REAL_NAME
Name-Email: $GPG_EMAIL
Expire-Date: 0
%no-protection
%commit
EOF
    )
    
    # Verify the key was actually created
    VERIFY_COUNT=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -c "sec" || true)
    if [ "$VERIFY_COUNT" -eq 0 ]; then
        log_error "Failed to generate GPG key. GPG output:"
        echo "$GPG_OUTPUT" >&2
        exit 1
    fi
    
    log_success "GPG key generated successfully in $GNUPGHOME"
}

#===================================================================================
# 3. GET GPG KEY ID
#===================================================================================
get_gpg_key_id() {
    log_info "Retrieving GPG key ID..."
    
    # Get the key ID from the sec line format: sec   ed25519/C1B3A7024D9463D6 2026-05-19 [SC]
    # We want the short key ID (C1B3A7024D9463D6) which is after the slash in field 2
    GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | \
                 grep "^sec" | head -1 | awk '{print $2}' | cut -d'/' -f2)
    
    if [ -z "$GPG_KEY_ID" ]; then
        log_error "Failed to retrieve GPG key ID"
        log_error "Available keys:"
        gpg --list-secret-keys --keyid-format LONG 2>/dev/null >&2
        exit 1
    fi
    
    # Validate key ID format (should be 16 hex characters for long format)
    if ! echo "$GPG_KEY_ID" | grep -qE '^[A-F0-9]{16}$'; then
        log_error "Invalid GPG key ID format: $GPG_KEY_ID"
        exit 1
    fi
    
    log_info "Extracted key ID: $GPG_KEY_ID"
    echo "$GPG_KEY_ID"
}

#===================================================================================
# 4. INITIALIZE PASS
#===================================================================================
init_pass() {
    local GPG_KEY_ID=$1
    log_info "Initializing pass with GPG key ID: $GPG_KEY_ID..."
    log_info "Pass store directory: $PASS_STORE_DIR"
    
    # Set PASSWORD_STORE_DIR environment variable
    export PASSWORD_STORE_DIR="$PASS_STORE_DIR"
    
    # Check if pass is already initialized
    if [ -d "$PASS_STORE_DIR" ]; then
        log_warning "Pass already initialized at $PASS_STORE_DIR. Skipping..."
        return
    fi
    
    # Create pass store directory
    mkdir -p "$PASS_STORE_DIR"
    chmod 700 "$PASS_STORE_DIR"
    
    # Initialize pass with the GPG key
    pass init "$GPG_KEY_ID" 2>/dev/null || true
    
    log_success "Pass initialized successfully at $PASS_STORE_DIR"
}

#===================================================================================
# 5. CONFIGURE DOCKER
#===================================================================================
configure_docker() {
    log_info "Configuring Docker to use credential helper..."
    log_info "Docker config directory: $HOME/.docker"

    # Create Docker config directory in the user's home directory
    mkdir -p "$HOME/.docker"

    # If a previous symlink exists, remove it so Docker gets a normal file again
    if [ -L "$HOME/.docker/config.json" ]; then
        log_info "Removing existing symlink: $HOME/.docker/config.json"
        rm -f "$HOME/.docker/config.json"
    fi

    # Create Docker config with credential helper using pass
    cat > "$HOME/.docker/config.json" <<EOF
{
    "auths": {},
    "credsStore": "pass"
}
EOF

    log_success "Docker configured with credential helper (pass)"
    log_info "Config location: $HOME/.docker/config.json"
}

#===================================================================================
# 6. SHOW GENERATED KEYS
#===================================================================================
show_keys() {
    log_info "Displaying generated keys and configuration..."
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  ENVIRONMENT VARIABLES${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo "GNUPGHOME=$GNUPGHOME"
    echo "PASSWORD_STORE_DIR=$PASS_STORE_DIR"
    echo "CREDS_DIR=$CREDS_DIR"
    echo "GPG_REAL_NAME=$GPG_REAL_NAME"
    echo "GPG_EMAIL=$GPG_EMAIL"
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  GPG KEYS${NC}"
    echo -e "${BLUE}========================================${NC}"
    gpg --list-secret-keys --keyid-format LONG
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  PASS CONFIGURATION${NC}"
    echo -e "${BLUE}========================================${NC}"
    if [ -d "$PASS_STORE_DIR" ]; then
        PASSWORD_STORE_DIR="$PASS_STORE_DIR" pass ls || log_warning "Pass store appears empty"
    else
        log_warning "Pass store not initialized"
    fi
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  DOCKER CONFIG${NC}"
    echo -e "${BLUE}========================================${NC}"
    cat "$HOME/.docker/config.json" 2>/dev/null || echo "Config file not found"
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  DOCKER CREDENTIALS HELPER STATUS${NC}"
    echo -e "${BLUE}========================================${NC}"
    GNUPGHOME="$GNUPGHOME" PASSWORD_STORE_DIR="$PASS_STORE_DIR" docker-credential-pass list 2>/dev/null || echo "No credentials stored yet"
    
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
    
    # Display usage and configuration
    log_info "Persistent credentials directory: $CREDS_DIR"
    log_info "GNUPGHOME: $GNUPGHOME"
    log_info "PASSWORD_STORE_DIR: $PASS_STORE_DIR"
    log_info "DOCKER_CONFIG_DIR: $DOCKER_CONFIG_DIR"
    echo ""
    
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
    log_warning "IMPORTANT: If you had previous Docker credentials, run 'docker logout' then 'docker login' in this shell after re-running the installer."
    echo ""
    
    configure_docker
    echo ""
    
    show_keys
    
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Installation completed successfully!                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}REQUIRED ENVIRONMENT VARIABLES FOR DOCKER OPERATIONS:${NC}"
    echo "export GNUPGHOME=$GNUPGHOME"
    echo "export PASSWORD_STORE_DIR=$PASS_STORE_DIR"
    echo ""
    echo -e "${YELLOW}ADD TO YOUR JENKINS AGENT CONFIGURATION:${NC}"
    echo "1. Set environment variables in Jenkins agent startup script:"
    echo "   export GNUPGHOME=$GNUPGHOME"
    echo "   export PASSWORD_STORE_DIR=$PASS_STORE_DIR"
    echo ""
    echo -e "${YELLOW}NEXT STEPS:${NC}"
    echo "1. Run: docker login registry.example.com"
    echo "2. Verify: docker-credential-pass list"
    echo "3. Logout and login again to apply new credentials helper configuration"
    echo "4. Verify by checking Docker config and credential helper status using the check-docker-keys.sh script"
    echo ""
    echo -e "${YELLOW}DOCKER LOGIN COMMAND:${NC}"
    echo "GNUPGHOME=$GNUPGHOME PASSWORD_STORE_DIR=$PASS_STORE_DIR docker login"
    echo ""
}

# Parse arguments and run main function
parse_arguments "$@"
main


#!/bin/bash

#===================================================================================
# Docker Credentials Helper Cleanup Script
# Safely removes GPG keys, pass store, and Docker credential entries
# Safe to run even if setup failed partway through
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

# Credentials directory (default to current directory)
CREDS_DIR="${1:-.}"
export GNUPGHOME="${CREDS_DIR}/.gnupg"
PASS_STORE_DIR="${CREDS_DIR}/.password-store"

# Main cleanup function
main() {
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  Docker Credentials Helper - CLEANUP SCRIPT               ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log_warning "This script will PERMANENTLY DELETE:"
    echo ""
    echo "  1. GPG keys at: $GNUPGHOME"
    echo "  2. Pass store at: $PASS_STORE_DIR"
    echo "  3. Docker credentials stored via docker-credential-pass"
    echo "  4. Docker config file: ~/.docker/config.json (optional)"
    echo ""
    
    # Confirm before proceeding
    read -p "Are you sure you want to proceed? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        log_info "Cleanup cancelled."
        exit 0
    fi
    
    echo ""
    log_info "Starting cleanup..."
    echo ""
    
    # Step 1: List and backup GPG keys (optional)
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  1. GPG Keys (Backup First)${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    GPG_KEY_COUNT=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -c "sec" || echo "0")
    if [ "$GPG_KEY_COUNT" -gt 0 ]; then
        log_info "Found $GPG_KEY_COUNT GPG key(s). Listing keys before deletion:"
        gpg --list-secret-keys --keyid-format LONG 2>/dev/null || true
        
        # Offer to create backup
        read -p "Create backup of GPG keys? (yes/no): " backup_choice
        if [[ "$backup_choice" == "yes" ]]; then
            BACKUP_DIR="$HOME/gpg-backup-$(date +%s)"
            mkdir -p "$BACKUP_DIR"
            gpg --export-secret-keys --armor > "$BACKUP_DIR/secret.asc" 2>/dev/null || true
            gpg --export --armor > "$BACKUP_DIR/public.asc" 2>/dev/null || true
            log_success "Backup created at: $BACKUP_DIR"
        fi
        
        # Extract key IDs and delete
        KEY_IDS=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep "^sec" | awk '{print $2}' | cut -d'/' -f2)
        for KEY_ID in $KEY_IDS; do
            log_info "Deleting GPG secret key: $KEY_ID"
            gpg --batch --yes --delete-secret-keys "$KEY_ID" 2>/dev/null || true
            
            log_info "Deleting GPG public key: $KEY_ID"
            gpg --batch --yes --delete-keys "$KEY_ID" 2>/dev/null || true
        done
        
        log_success "All GPG keys deleted"
    else
        log_info "No GPG keys found"
    fi
    echo ""
    
    # Step 2: Remove pass store and docker-credential-helpers entries
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  2. Pass Store & Credential Entries${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [ -d "$PASS_STORE_DIR" ]; then
        log_info "Listing pass store before deletion:"
        PASSWORD_STORE_DIR="$PASS_STORE_DIR" pass ls 2>/dev/null || log_info "Pass store empty"
        
        log_info "Erasing docker-credential-helpers entry via helper..."
        printf 'https://index.docker.io/v1/' | GNUPGHOME="$GNUPGHOME" PASSWORD_STORE_DIR="$PASS_STORE_DIR" docker-credential-pass erase 2>/dev/null || log_warning "Entry not found in pass store (may already be gone)"
        
        log_info "Removing pass store directory: $PASS_STORE_DIR"
        rm -rf "$PASS_STORE_DIR"
        log_success "Pass store removed"
    else
        log_info "Pass store directory not found"
    fi
    echo ""
    
    # Step 3: Remove GNUPGHOME directory
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  3. GNUPGHOME Directory${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [ -d "$GNUPGHOME" ]; then
        log_info "Removing GNUPGHOME directory: $GNUPGHOME"
        rm -rf "$GNUPGHOME"
        log_success "GNUPGHOME removed"
    else
        log_info "GNUPGHOME directory not found"
    fi
    echo ""
    
    # Step 4: Docker cleanup (optional)
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  4. Docker Configuration${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    read -p "Remove Docker config (~/.docker/config.json)? (yes/no): " docker_cleanup
    if [[ "$docker_cleanup" == "yes" ]]; then
        log_info "Running docker logout..."
        docker logout 2>/dev/null || log_warning "Docker logout had warnings (may be normal)"
        
        if [ -f "$HOME/.docker/config.json" ]; then
            log_info "Removing Docker config: $HOME/.docker/config.json"
            rm -f "$HOME/.docker/config.json"
            log_success "Docker config removed"
        else
            log_info "Docker config not found"
        fi
    else
        log_info "Skipping Docker config cleanup"
    fi
    echo ""
    
    # Summary
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Cleanup completed successfully!                          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    log_success "You can now re-run the installer:"
    echo "  bash install-docker-credentials.sh $CREDS_DIR"
    echo ""
}

# Display usage if requested
if [[ " $* " == *" --help "* ]] || [[ " $* " == *" -h "* ]]; then
    echo "Usage: $0 [CREDS_DIR]"
    echo ""
    echo "Arguments:"
    echo "  CREDS_DIR  Directory where GPG keys and pass credentials are stored"
    echo "             Default: current directory (.)"
    echo ""
    echo "This script will:"
    echo "  1. Back up GPG keys (optional)"
    echo "  2. Delete all GPG secret and public keys"
    echo "  3. Remove pass store and credential entries"
    echo "  4. Remove GNUPGHOME directory"
    echo "  5. Remove Docker config (optional)"
    echo ""
    echo "Example:"
    echo "  bash $0 /home/nhqb"
    echo "  bash $0"
    exit 0
fi

# Run main function
main "$@"

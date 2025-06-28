#!/bin/bash

# GitHub Secrets Setup Script for Jaguar AGI CI/CD Pipeline
# This script helps you configure GitHub secrets for automated deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🔐 GitHub Secrets Setup for Jaguar AGI CI/CD"
echo "============================================="
echo ""

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is not installed."
    echo ""
    echo "Please install it first:"
    echo "  macOS: brew install gh"
    echo "  Ubuntu/Debian: sudo apt install gh"
    echo "  Or visit: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated with GitHub CLI
if ! gh auth status &> /dev/null; then
    print_warning "You are not authenticated with GitHub CLI."
    echo ""
    print_status "Please authenticate first:"
    echo "  gh auth login"
    echo ""
    read -p "Press Enter after you've authenticated with GitHub CLI..."
fi

# Verify we're in the correct repository
REPO_URL=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$REPO_URL" != *"serenelion/ai-agents-masterclass"* ]]; then
    print_error "This script should be run from the ai-agents-masterclass repository."
    print_status "Current remote URL: $REPO_URL"
    exit 1
fi

print_success "GitHub CLI is installed and authenticated"
echo ""

# Function to set a GitHub secret
set_github_secret() {
    local secret_name="$1"
    local secret_description="$2"
    local secret_value="$3"
    
    if [ -z "$secret_value" ]; then
        print_warning "Skipping $secret_name (no value provided)"
        return
    fi
    
    print_status "Setting secret: $secret_name"
    echo "$secret_value" | gh secret set "$secret_name"
    print_success "✅ $secret_name set successfully"
}

# Function to generate secure password
generate_password() {
    openssl rand -base64 32
}

# Function to prompt for input with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local result
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " result
        echo "${result:-$default}"
    else
        read -p "$prompt: " result
        echo "$result"
    fi
}

# Function to prompt for secret input (hidden)
prompt_secret() {
    local prompt="$1"
    local result
    
    read -s -p "$prompt: " result
    echo ""
    echo "$result"
}

echo "📋 Let's configure your GitHub secrets..."
echo ""

# 1. Digital Ocean Access Token
print_status "1. Digital Ocean Access Token"
echo "   Get this from: https://cloud.digitalocean.com/account/api/tokens"
echo "   Create a new token with 'Write' scope"
echo ""
DIGITALOCEAN_ACCESS_TOKEN=$(prompt_secret "Enter your Digital Ocean Access Token")
echo ""

# 2. Droplet IP
print_status "2. Droplet IP Address"
echo "   This is the public IP of your droplet (ID: 504791828)"
echo ""

# Try to get droplet IP automatically if doctl is available and configured
if command -v doctl &> /dev/null && doctl auth list &> /dev/null; then
    print_status "Attempting to get droplet IP automatically..."
    AUTO_DROPLET_IP=$(doctl compute droplet list --format "ID,PublicIPv4" --no-header | grep "504791828" | awk '{print $2}' || echo "")
    if [ -n "$AUTO_DROPLET_IP" ]; then
        print_success "Found droplet IP: $AUTO_DROPLET_IP"
        DROPLET_IP=$(prompt_with_default "Droplet IP" "$AUTO_DROPLET_IP")
    else
        print_warning "Could not automatically detect droplet IP"
        DROPLET_IP=$(prompt_with_default "Droplet IP" "")
    fi
else
    DROPLET_IP=$(prompt_with_default "Droplet IP" "")
fi
echo ""

# 3. Droplet User
print_status "3. Droplet SSH User"
echo "   Usually 'root' or 'ubuntu' depending on your droplet setup"
echo ""
DROPLET_USER=$(prompt_with_default "SSH Username" "root")
echo ""

# 4. SSH Private Key
print_status "4. SSH Private Key"
echo "   This is the private key for SSH access to your droplet"
echo "   If you don't have one, generate it with:"
echo "   ssh-keygen -t rsa -b 4096 -C 'github-actions@yourdomain.com' -f ~/.ssh/github_actions_key"
echo ""
echo "   Then copy the public key to your droplet:"
echo "   ssh-copy-id -i ~/.ssh/github_actions_key.pub $DROPLET_USER@$DROPLET_IP"
echo ""

# Check for existing SSH keys
SSH_KEY_PATH=""
if [ -f ~/.ssh/id_rsa ]; then
    SSH_KEY_PATH="~/.ssh/id_rsa"
elif [ -f ~/.ssh/github_actions_key ]; then
    SSH_KEY_PATH="~/.ssh/github_actions_key"
fi

if [ -n "$SSH_KEY_PATH" ]; then
    print_status "Found SSH key at: $SSH_KEY_PATH"
    USE_EXISTING=$(prompt_with_default "Use this key? (y/n)" "y")
    if [[ "$USE_EXISTING" =~ ^[Yy] ]]; then
        SSH_PRIVATE_KEY=$(cat "${SSH_KEY_PATH/#\~/$HOME}")
    else
        echo "Please paste your SSH private key (press Ctrl+D when done):"
        SSH_PRIVATE_KEY=$(cat)
    fi
else
    echo "Please paste your SSH private key (press Ctrl+D when done):"
    SSH_PRIVATE_KEY=$(cat)
fi
echo ""

# 5. Generate secure passwords
print_status "5. Generating secure passwords and keys..."
echo ""

POSTGRES_PASSWORD=$(generate_password)
print_success "Generated PostgreSQL password"

N8N_ENCRYPTION_KEY=$(generate_password)
print_success "Generated N8N encryption key"

N8N_USER_MANAGEMENT_JWT_SECRET=$(generate_password)
print_success "Generated N8N JWT secret"

echo ""
print_status "6. Setting GitHub secrets..."
echo ""

# Set all secrets
set_github_secret "DIGITALOCEAN_ACCESS_TOKEN" "Digital Ocean API token" "$DIGITALOCEAN_ACCESS_TOKEN"
set_github_secret "DROPLET_IP" "Droplet IP address" "$DROPLET_IP"
set_github_secret "DROPLET_USER" "SSH username" "$DROPLET_USER"
set_github_secret "SSH_PRIVATE_KEY" "SSH private key" "$SSH_PRIVATE_KEY"
set_github_secret "POSTGRES_PASSWORD" "PostgreSQL password" "$POSTGRES_PASSWORD"
set_github_secret "N8N_ENCRYPTION_KEY" "N8N encryption key" "$N8N_ENCRYPTION_KEY"
set_github_secret "N8N_USER_MANAGEMENT_JWT_SECRET" "N8N JWT secret" "$N8N_USER_MANAGEMENT_JWT_SECRET"

echo ""
print_success "🎉 All GitHub secrets have been configured!"
echo ""

# Save credentials locally for reference
CREDS_FILE="deployment-credentials.txt"
print_status "Saving credentials to $CREDS_FILE for your reference..."

cat > "$CREDS_FILE" << EOF
# Jaguar AGI Deployment Credentials
# Generated on: $(date)
# 
# IMPORTANT: Keep this file secure and do not commit it to git!

DROPLET_IP=$DROPLET_IP
DROPLET_USER=$DROPLET_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY
N8N_USER_MANAGEMENT_JWT_SECRET=$N8N_USER_MANAGEMENT_JWT_SECRET

# SSH Connection Test:
# ssh $DROPLET_USER@$DROPLET_IP

# Manual Deployment Test:
# ssh $DROPLET_USER@$DROPLET_IP
# git clone https://github.com/serenelion/ai-agents-masterclass.git
# cd ai-agents-masterclass/jaguar-local/production
# chmod +x deploy.sh
# ./deploy.sh
EOF

chmod 600 "$CREDS_FILE"
print_success "Credentials saved to $CREDS_FILE"

echo ""
echo "📋 Next Steps:"
echo "=============="
echo ""
echo "1. 🔐 Test SSH access to your droplet:"
echo "   ssh $DROPLET_USER@$DROPLET_IP"
echo ""
echo "2. 🌐 Configure DNS records:"
echo "   n8n.thespatialnetwork.net → $DROPLET_IP"
echo "   ai.thespatialnetwork.net → $DROPLET_IP"
echo ""
echo "3. 🚀 Test the deployment:"
echo "   git add ."
echo "   git commit -m 'Add CI/CD pipeline'"
echo "   git push origin main"
echo ""
echo "4. 👀 Monitor the deployment:"
echo "   Go to: https://github.com/serenelion/ai-agents-masterclass/actions"
echo ""
echo "5. 🎯 Access your services after deployment:"
echo "   N8N: https://n8n.thespatialnetwork.net"
echo "   OpenWebUI: https://ai.thespatialnetwork.net"
echo ""

print_warning "Remember to:"
echo "• Keep your credentials file ($CREDS_FILE) secure"
echo "• Test SSH access before pushing to main"
echo "• Ensure DNS records are configured"
echo "• Monitor the GitHub Actions workflow"

echo ""
print_success "Setup complete! 🎉"

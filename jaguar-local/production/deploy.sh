#!/bin/bash

# Jaguar AGI Production Deployment Script
# This script deploys the Jaguar AGI system to Digital Ocean

set -e

echo "🐆 Jaguar AGI Production Deployment Script"
echo "=========================================="

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create deployment directory
DEPLOY_DIR="/opt/jaguar-agi"
print_status "Creating deployment directory: $DEPLOY_DIR"

if [ ! -d "$DEPLOY_DIR" ]; then
    sudo mkdir -p "$DEPLOY_DIR"
    sudo chown $USER:$USER "$DEPLOY_DIR"
    print_success "Created deployment directory"
else
    print_warning "Deployment directory already exists"
fi

# Copy files to deployment directory
print_status "Copying deployment files..."

cp docker-compose.prod.yml "$DEPLOY_DIR/"
cp Caddyfile "$DEPLOY_DIR/"
cp .env.prod.example "$DEPLOY_DIR/"
cp openwebui_n8n_pipe.py "$DEPLOY_DIR/"
cp Jaguar_AGI_Production_Workflow.json "$DEPLOY_DIR/"

# Create workflows directory
mkdir -p "$DEPLOY_DIR/workflows"
cp Jaguar_AGI_Production_Workflow.json "$DEPLOY_DIR/workflows/"

print_success "Files copied successfully"

# Create .env.prod if it doesn't exist
if [ ! -f "$DEPLOY_DIR/.env.prod" ]; then
    print_status "Creating production environment file..."
    cp "$DEPLOY_DIR/.env.prod.example" "$DEPLOY_DIR/.env.prod"
    
    # Generate secure passwords and keys
    POSTGRES_PASSWORD=$(openssl rand -base64 32)
    N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)
    N8N_JWT_SECRET=$(openssl rand -base64 32)
    
    # Update .env.prod with generated values
    sed -i "s/your_secure_password_here_change_this/$POSTGRES_PASSWORD/g" "$DEPLOY_DIR/.env.prod"
    sed -i "s/your_secure_encryption_key_here_change_this_32_chars_min/$N8N_ENCRYPTION_KEY/g" "$DEPLOY_DIR/.env.prod"
    sed -i "s/your_secure_jwt_secret_here_change_this_32_chars_min/$N8N_JWT_SECRET/g" "$DEPLOY_DIR/.env.prod"
    
    chmod 600 "$DEPLOY_DIR/.env.prod"
    print_success "Environment file created with secure passwords"
    print_warning "Please review and update $DEPLOY_DIR/.env.prod with your specific configuration"
else
    print_warning "Environment file already exists, skipping generation"
fi

# Create log directories
print_status "Creating log directories..."
sudo mkdir -p /var/log/caddy
sudo chown $USER:$USER /var/log/caddy
print_success "Log directories created"

# Change to deployment directory
cd "$DEPLOY_DIR"

# Pull Docker images
print_status "Pulling Docker images..."
docker-compose -f docker-compose.prod.yml pull
print_success "Docker images pulled"

# Create Docker networks and volumes
print_status "Creating Docker networks and volumes..."
docker-compose -f docker-compose.prod.yml --env-file .env.prod up --no-start
print_success "Networks and volumes created"

# Start services
print_status "Starting Jaguar AGI services..."
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d

# Wait for services to start
print_status "Waiting for services to start..."
sleep 30

# Check service status
print_status "Checking service status..."
docker-compose -f docker-compose.prod.yml ps

# Install LangChain nodes in n8n
print_status "Installing LangChain nodes in n8n..."
if docker exec jaguar-n8n npm list @n8n/n8n-nodes-langchain &> /dev/null; then
    print_warning "LangChain nodes already installed"
else
    docker exec jaguar-n8n npm install @n8n/n8n-nodes-langchain
    print_status "Restarting n8n to load new nodes..."
    docker-compose -f docker-compose.prod.yml restart n8n
    print_success "LangChain nodes installed"
fi

# Test services
print_status "Testing services..."

# Test n8n
if curl -f -s http://localhost:5678/healthz > /dev/null; then
    print_success "N8N is responding"
else
    print_warning "N8N may not be ready yet"
fi

# Test OpenWebUI
if curl -f -s http://localhost:8080/health > /dev/null; then
    print_success "OpenWebUI is responding"
else
    print_warning "OpenWebUI may not be ready yet"
fi

# Display deployment information
echo ""
echo "🎉 Jaguar AGI Deployment Complete!"
echo "=================================="
echo ""
echo "📊 Service URLs:"
echo "  • N8N: https://n8n.thespatialnetwork.net"
echo "  • OpenWebUI: https://ai.thespatialnetwork.net"
echo "  • Health Check: https://health.thespatialnetwork.net"
echo ""
echo "📁 Deployment Directory: $DEPLOY_DIR"
echo "📝 Environment File: $DEPLOY_DIR/.env.prod"
echo "📋 Logs: /var/log/caddy/"
echo ""
echo "🔧 Next Steps:"
echo "  1. Configure DNS records for your domains"
echo "  2. Access n8n and create your admin account"
echo "  3. Import the Jaguar workflow from: $DEPLOY_DIR/workflows/"
echo "  4. Access OpenWebUI and install the pipe function"
echo "  5. Test the integration between n8n and OpenWebUI"
echo ""
echo "📚 Documentation: $DEPLOY_DIR/jaguar-production-deployment.md"
echo ""
echo "🚨 Important:"
echo "  • Review and update $DEPLOY_DIR/.env.prod"
echo "  • Set up monitoring and backups"
echo "  • Configure firewall rules"
echo ""

# Display useful commands
echo "🛠️  Useful Commands:"
echo "  • View logs: docker-compose -f $DEPLOY_DIR/docker-compose.prod.yml logs -f"
echo "  • Restart services: docker-compose -f $DEPLOY_DIR/docker-compose.prod.yml restart"
echo "  • Stop services: docker-compose -f $DEPLOY_DIR/docker-compose.prod.yml down"
echo "  • Update services: docker-compose -f $DEPLOY_DIR/docker-compose.prod.yml pull && docker-compose -f $DEPLOY_DIR/docker-compose.prod.yml up -d"
echo ""

print_success "Deployment script completed successfully!"

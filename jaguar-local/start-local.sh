#!/bin/bash

# Jaguar Local Development Quick Start Script

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐆 Starting Jaguar AI Developer Agent (Local Development)${NC}"
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creating .env file from template...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}Please edit .env file with your API keys before continuing.${NC}"
    echo "Required: OPENAI_API_KEY, GITHUB_TOKEN"
    echo ""
    read -p "Press Enter after configuring .env file..."
fi

# Detect system type
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OS
    echo -e "${BLUE}Detected macOS - starting without GPU profile${NC}"
    PROFILE=""
elif command -v nvidia-smi &> /dev/null; then
    # NVIDIA GPU detected
    echo -e "${BLUE}Detected NVIDIA GPU - starting with GPU profile${NC}"
    PROFILE="--profile gpu-nvidia"
else
    # CPU only
    echo -e "${BLUE}No GPU detected - starting with CPU profile${NC}"
    PROFILE="--profile cpu"
fi

# Start services
echo -e "${BLUE}Starting Docker services...${NC}"
docker compose $PROFILE up -d

echo ""
echo -e "${GREEN}✅ Jaguar services are starting up!${NC}"
echo ""
echo "🌐 Access URLs:"
echo "  • OpenWebUI (Jaguar Interface): http://localhost:3000"
echo "  • N8N (Workflow Management):   http://localhost:5678"
echo "  • Qdrant (Vector Database):    http://localhost:6333"
echo "  • Flowise (AI Tools):          http://localhost:3001"
echo ""
echo "📋 Next Steps:"
echo "  1. Wait 2-3 minutes for all services to start"
echo "  2. Open http://localhost:3000 and create your account"
echo "  3. Add the Jaguar pipe function from n8n_pipe.py"
echo "  4. Open http://localhost:5678 and configure n8n credentials"
echo "  5. Index the knowledge base: curl -X POST http://localhost:5678/webhook/index-masterclass"
echo ""
echo "🔧 Useful Commands:"
echo "  • View logs: docker compose logs -f"
echo "  • Stop services: docker compose down"
echo "  • Restart: docker compose $PROFILE restart"
echo ""
echo -e "${GREEN}🐆 Jaguar is ready to guide the evolution of agents with natural wisdom!${NC}"

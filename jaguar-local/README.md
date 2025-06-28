# Jaguar AI Developer Agent - Local Development

Jaguar is The Spatial Network's master AI developer agent that combines OpenWebUI with n8n to create a powerful workflow automation system with natural language interface.

## Mission
"Guide the evolution of agents with natural wisdom"

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Git
- 8GB+ RAM recommended
- GPU support (optional, for faster inference)

### 1. Clone and Setup
```bash
git clone https://github.com/The-Spatial-Network/ai-agents-masterclass.git
cd ai-agents-masterclass/jaguar-local
cp .env.example .env
```

### 2. Configure Environment
Edit `.env` file with your API keys:
```bash
# Required
OPENAI_API_KEY=your_openai_api_key_here
GITHUB_TOKEN=your_github_token_here

# Optional (will use defaults if not set)
POSTGRES_PASSWORD=your_secure_password
N8N_ENCRYPTION_KEY=your_encryption_key
```

### 3. Start Jaguar
```bash
# For CPU-only systems
docker compose --profile cpu up -d

# For NVIDIA GPU systems
docker compose --profile gpu-nvidia up -d

# For Mac/Apple Silicon (run Ollama locally)
docker compose up -d
```

### 4. Access Jaguar
- **OpenWebUI (Jaguar Interface)**: http://localhost:3000
- **N8N (Workflow Management)**: http://localhost:5678
- **Qdrant (Vector Database)**: http://localhost:6333
- **Flowise (Additional AI Tools)**: http://localhost:3001

## Setup Guide

### Initial Configuration

1. **Setup OpenWebUI** (http://localhost:3000)
   - Create your admin account
   - Go to Workspace → Functions
   - Add the Jaguar pipe function from `n8n_pipe.py`
   - Configure the n8n_url to: `http://localhost:5678/webhook/jaguar-agent`

2. **Setup N8N** (http://localhost:5678)
   - Create your account
   - Import the Jaguar workflows from `n8n/backup/workflows/`
   - Configure credentials:
     - Ollama: `http://ollama:11434`
     - Postgres: Use credentials from `.env`
     - Qdrant: `http://qdrant:6333`
     - GitHub: Your GitHub token

3. **Index Knowledge Base**
   - Trigger the "Masterclass Knowledge Indexer" workflow
   - Or call: `curl -X POST http://localhost:5678/webhook/index-masterclass`

### Credentials Setup

#### Ollama
- **URL**: `http://ollama:11434` (or `http://host.docker.internal:11434` for Mac)

#### PostgreSQL
- **Host**: `postgres`
- **Database**: Value from `POSTGRES_DB` in `.env`
- **Username**: Value from `POSTGRES_USER` in `.env`
- **Password**: Value from `POSTGRES_PASSWORD` in `.env`

#### Qdrant
- **URL**: `http://qdrant:6333`
- **API Key**: Any value (local instance)

#### GitHub
- **Token**: Your GitHub personal access token with repo permissions

## Architecture

### System Components

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   OpenWebUI     │    │       N8N        │    │     Qdrant      │
│   (Frontend)    │◄──►│   (Workflows)    │◄──►│ (Vector Store)  │
│                 │    │                  │    │                 │
│ - Chat Interface│    │ - Jaguar Agent   │    │ - Knowledge Base│
│ - Jaguar Pipe   │    │ - GitHub Ops     │    │ - Embeddings    │
│ - Claude Model  │    │ - RAG System     │    │ - Search        │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌──────────────────┐
                    │   PostgreSQL     │
                    │   (Memory)       │
                    │                  │
                    │ - Chat History   │
                    │ - Sessions       │
                    │ - Workflow Data  │
                    └──────────────────┘
```

### Data Flow

1. **User Input** → OpenWebUI chat interface
2. **Jaguar Pipe** → Processes request and calls n8n webhook
3. **N8N Workflow** → Routes to appropriate handler:
   - RAG queries → Qdrant vector search
   - GitHub operations → GitHub API
   - Workflow management → N8N API
4. **Response** → Back through pipe to OpenWebUI
5. **Memory** → Stored in PostgreSQL for context

## Features

### Core Capabilities
- **Natural Language Workflow Creation**: Describe workflows in plain English
- **GitHub Repository Management**: Create repos, commit files, manage PRs
- **Knowledge Base Queries**: Access complete AI agents masterclass
- **Workflow CRUD Operations**: Create, read, update, delete n8n workflows
- **Multi-Model Support**: Switch between different AI models
- **Persistent Memory**: Maintain conversation context across sessions

### Masterclass Integration
- **Progressive Learning**: Follows masterclass lesson progression
- **Pattern Recognition**: Identifies and applies proven patterns
- **Best Practices**: References specific examples and lessons
- **Code Generation**: Creates code based on masterclass templates

## Usage Examples

### Create a Simple Workflow
```
"Create a workflow that sends me a daily email with weather updates"
```

### GitHub Operations
```
"Create a new repository called 'my-ai-agent' with a basic Python structure"
```

### Knowledge Queries
```
"How do I implement RAG like in masterclass lesson 5?"
```

### Workflow Management
```
"Show me all my active workflows and their status"
```

## Development

### File Structure
```
jaguar-local/
├── docker-compose.yml          # Main orchestration
├── .env.example               # Environment template
├── n8n_pipe.py               # OpenWebUI pipe function
├── n8n/backup/workflows/     # Pre-built workflows
├── system-prompts/           # AI system prompts
├── shared/                   # Shared data volume
└── README.md                # This file
```

### Customization

#### Adding New Workflows
1. Create workflow in n8n interface
2. Export as JSON
3. Place in `n8n/backup/workflows/`
4. Restart n8n container to auto-import

#### Modifying System Prompts
1. Edit files in `system-prompts/`
2. Update the Jaguar Agent Workflow in n8n
3. Test changes through OpenWebUI

#### Adding New Models
1. Configure in OpenWebUI admin panel
2. Update model selection in Jaguar workflows
3. Test compatibility with pipe function

## Production Deployment

### Environment Variables for Production
```bash
# Update these for production deployment
PRODUCTION_N8N_URL=https://n8n.thespatialnetwork.net
PRODUCTION_OPENWEBUI_URL=https://ai.thespatialnetwork.net

# Security
N8N_ENCRYPTION_KEY=your_production_encryption_key
POSTGRES_PASSWORD=your_secure_production_password
```

### Deployment Steps
1. Update environment variables for production URLs
2. Configure SSL/TLS certificates
3. Set up proper firewall rules
4. Configure backup strategies for PostgreSQL and Qdrant
5. Monitor resource usage and scale as needed

## Troubleshooting

### Common Issues

#### Ollama Models Not Loading
```bash
# Check if models are downloaded
docker exec jaguar-ollama ollama list

# Pull models manually if needed
docker exec jaguar-ollama ollama pull llama3.1
docker exec jaguar-ollama ollama pull nomic-embed-text
```

#### N8N Workflows Not Importing
```bash
# Check import logs
docker logs jaguar-n8n-import

# Manually import if needed
docker exec jaguar-n8n n8n import:workflow --input=/backup/workflows
```

#### Qdrant Connection Issues
```bash
# Check Qdrant status
curl http://localhost:6333/health

# Restart if needed
docker restart jaguar-qdrant
```

### Logs and Monitoring
```bash
# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f jaguar-openwebui
docker compose logs -f jaguar-n8n
docker compose logs -f jaguar-qdrant
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly with the local setup
5. Submit a pull request

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](../LICENSE) file for details.

## Support

- **Documentation**: Check the AI Agents Masterclass videos
- **Issues**: Create GitHub issues for bugs or feature requests
- **Community**: Join The Spatial Network community discussions

---

**Jaguar**: Guiding the evolution of agents with natural wisdom 🐆

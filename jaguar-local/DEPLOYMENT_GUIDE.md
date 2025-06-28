# Jaguar Production Deployment Guide

This guide will help you deploy Jaguar to your Digital Ocean droplet `n8n1671onubuntu2204lts-s-2vcpu-4gb-120gb-intel-nyc1-01` within 1 hour.

## Quick Deployment (1 Hour Timeline)

### Prerequisites (5 minutes)
1. **SSH Access** to your Digital Ocean droplet
2. **Domain DNS** configured:
   - `n8n.thespatialnetwork.net` → Your droplet IP
   - `ai.thespatialnetwork.net` → Your droplet IP
3. **API Keys** ready:
   - OpenAI API key
   - GitHub personal access token

### Step 1: Server Preparation (10 minutes)

SSH into your droplet:
```bash
ssh root@your-droplet-ip
```

Install Docker and Docker Compose:
```bash
# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Start Docker
systemctl start docker
systemctl enable docker
```

### Step 2: Clone and Setup (5 minutes)

```bash
# Clone the repository
git clone https://github.com/The-Spatial-Network/ai-agents-masterclass.git
cd ai-agents-masterclass/jaguar-local/production

# Copy environment template
cp .env.prod.example .env.prod
```

### Step 3: Configure Environment (10 minutes)

Edit the production environment file:
```bash
nano .env.prod
```

**Critical configurations to update:**
```bash
# Domains (should already be correct)
PRODUCTION_N8N_DOMAIN=n8n.thespatialnetwork.net
PRODUCTION_OPENWEBUI_DOMAIN=ai.thespatialnetwork.net

# Database (generate secure passwords)
POSTGRES_PASSWORD=your_very_secure_password_here

# N8N Security (generate 32+ character keys)
N8N_ENCRYPTION_KEY=your_32_character_encryption_key_here
N8N_USER_MANAGEMENT_JWT_SECRET=your_jwt_secret_here

# OpenWebUI Security
OPENWEBUI_SECRET_KEY=your_openwebui_secret_key_here

# API Keys
OPENAI_API_KEY=your_openai_api_key_here
GITHUB_TOKEN=your_github_token_here

# Admin credentials
FLOWISE_PASSWORD=your_secure_flowise_password
```

**Quick key generation:**
```bash
# Generate secure keys
openssl rand -hex 32  # For N8N_ENCRYPTION_KEY
openssl rand -hex 24  # For JWT secrets
openssl rand -hex 16  # For other secrets
```

### Step 4: Deploy Jaguar (15 minutes)

```bash
# Make deployment script executable (already done in repo)
chmod +x deploy.sh

# Start deployment
./deploy.sh start
```

The script will:
1. Pull all Docker images
2. Start all services
3. Configure SSL certificates automatically
4. Run health checks

### Step 5: Initial Configuration (10 minutes)

#### Configure N8N (https://n8n.thespatialnetwork.net)
1. Create your admin account
2. Import workflows are automatically loaded
3. Configure credentials:
   - **Ollama**: `http://ollama:11434`
   - **PostgreSQL**: Use values from `.env.prod`
   - **Qdrant**: `http://qdrant:6333`
   - **GitHub**: Your GitHub token

#### Configure OpenWebUI (https://ai.thespatialnetwork.net)
1. Create your admin account
2. Go to **Workspace → Functions**
3. Add new function with content from `../n8n_pipe.py`
4. Configure function settings:
   - **n8n_url**: `https://n8n.thespatialnetwork.net/webhook/jaguar-agent`
   - Enable RAG and GitHub operations

### Step 6: Index Knowledge Base (5 minutes)

Trigger the knowledge indexing:
```bash
curl -X POST https://n8n.thespatialnetwork.net/webhook/index-masterclass
```

Or trigger manually in n8n interface.

## Verification Checklist

### Service Health
```bash
# Check all services
./deploy.sh status

# Check specific service logs
./deploy.sh logs jaguar-n8n-prod
./deploy.sh logs jaguar-openwebui-prod
```

### URL Access
- ✅ https://ai.thespatialnetwork.net (OpenWebUI)
- ✅ https://n8n.thespatialnetwork.net (N8N)
- ✅ SSL certificates automatically configured

### Functionality Tests
1. **Chat with Jaguar**: Ask "How do I create a basic agent like in masterclass lesson 1?"
2. **GitHub Integration**: "Create a test repository"
3. **Workflow Creation**: "Create a simple workflow that logs a message"

## Post-Deployment Configuration

### Security Hardening
```bash
# Configure firewall
ufw allow 22    # SSH
ufw allow 80    # HTTP
ufw allow 443   # HTTPS
ufw enable

# Disable root SSH (optional)
# Edit /etc/ssh/sshd_config: PermitRootLogin no
```

### Monitoring Setup
```bash
# View real-time logs
./deploy.sh logs

# Check service health
./deploy.sh health

# Create backup
./deploy.sh backup
```

### Regular Maintenance
```bash
# Update services (weekly)
./deploy.sh update

# Backup data (automated daily at 2 AM)
# Manual backup: ./deploy.sh backup
```

## Troubleshooting

### Common Issues

#### SSL Certificate Issues
```bash
# Check Caddy logs
docker logs jaguar-caddy

# Restart Caddy if needed
docker restart jaguar-caddy
```

#### N8N Connection Issues
```bash
# Check N8N logs
./deploy.sh logs jaguar-n8n-prod

# Restart N8N
docker restart jaguar-n8n-prod
```

#### Ollama Model Loading
```bash
# Check available models
docker exec jaguar-ollama-prod ollama list

# Pull models manually if needed
docker exec jaguar-ollama-prod ollama pull llama3.1
docker exec jaguar-ollama-prod ollama pull nomic-embed-text
```

### Performance Optimization

#### For 2vCPU/4GB Droplet
```bash
# Monitor resource usage
docker stats

# If memory is tight, disable Flowise temporarily
docker stop jaguar-flowise-prod
```

#### Scale Up if Needed
- Upgrade to 4vCPU/8GB for better performance
- Add GPU support for faster inference

## Integration with OpenWebUI

### Setting up the N8N Pipe Function

1. **Access OpenWebUI**: https://ai.thespatialnetwork.net
2. **Navigate to Functions**: Workspace → Functions → Add Function
3. **Function Configuration**:
   ```python
   # Copy content from jaguar-local/n8n_pipe.py
   # Configure valves:
   n8n_url: https://n8n.thespatialnetwork.net/webhook/jaguar-agent
   enable_rag: true
   github_operations: true
   ```

### Model Configuration

1. **Add Claude Sonnet 4** (if available):
   - Go to Admin Panel → Models
   - Add external model endpoint
   - Use system prompt from `system-prompts/jaguar-openwebui-system-prompt.md`

2. **Configure Ollama Models**:
   - Models are automatically available
   - Use Llama 3.1 as fallback

## Backup and Recovery

### Automated Backups
- Database backups: Daily at 2 AM
- Full system backups: Weekly
- Retention: 30 days

### Manual Backup
```bash
./deploy.sh backup
```

### Recovery Process
```bash
# Stop services
./deploy.sh stop

# Restore from backup
tar -xzf backups/jaguar_backup_TIMESTAMP.tar.gz

# Restore database
docker exec jaguar-postgres-prod psql -U $POSTGRES_USER -d $POSTGRES_DB < backups/postgres_TIMESTAMP.sql

# Start services
./deploy.sh start
```

## Success Metrics

After deployment, you should have:

✅ **Jaguar AI Agent** accessible at https://ai.thespatialnetwork.net  
✅ **N8N Workflows** accessible at https://n8n.thespatialnetwork.net  
✅ **SSL certificates** automatically configured  
✅ **Knowledge base** indexed with all masterclass content  
✅ **GitHub integration** working for repository operations  
✅ **RAG system** answering questions about the masterclass  
✅ **Workflow creation** via natural language  
✅ **Persistent memory** across chat sessions  

## Next Steps

1. **Test Core Functionality**: Try creating workflows and GitHub repos
2. **Customize System Prompts**: Adjust for your specific use cases
3. **Add Team Members**: Configure additional user accounts
4. **Monitor Performance**: Set up alerts and monitoring
5. **Scale as Needed**: Upgrade resources based on usage

---

**Deployment Time**: ~45 minutes  
**Total Setup Time**: ~1 hour including testing

🐆 **Jaguar is now ready to guide the evolution of agents with natural wisdom!**

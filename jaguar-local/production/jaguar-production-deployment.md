# Jaguar AGI Production Deployment Guide

## 🚀 Digital Ocean Deployment

This guide will help you deploy the Jaguar AGI system to Digital Ocean to integrate `n8n.thespatialnetwork.net` with `ai.thespatialnetwork.net`.

## 📋 Prerequisites

- Digital Ocean account with Docker Droplet
- Domain names configured:
  - `n8n.thespatialnetwork.net`
  - `ai.thespatialnetwork.net`
- SSL certificates (Let's Encrypt recommended)

## 🔧 Step 1: Server Setup

### Create Digital Ocean Droplet
```bash
# Recommended specs for production:
# - 4 vCPUs
# - 8GB RAM
# - 160GB SSD
# - Ubuntu 22.04 LTS
```

### Install Dependencies
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Caddy for reverse proxy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

## 📁 Step 2: Deploy Files

### Upload Production Files
```bash
# Create deployment directory
mkdir -p /opt/jaguar-agi
cd /opt/jaguar-agi

# Copy these files to the server:
# - docker-compose.prod.yml
# - .env.prod
# - Caddyfile
# - openwebui_n8n_pipe.py
# - Jaguar_AGI_Production_Workflow.json
```

## 🐳 Step 3: Production Docker Compose

Create `/opt/jaguar-agi/docker-compose.prod.yml`:

```yaml
version: '3.8'

volumes:
  n8n_storage:
  postgres_storage:
  qdrant_storage:
  caddy_data:
  caddy_config:

networks:
  jaguar:

services:
  caddy:
    image: caddy:2-alpine
    container_name: jaguar-caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - jaguar

  postgres:
    image: postgres:16-alpine
    container_name: jaguar-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    volumes:
      - postgres_storage:/var/lib/postgresql/data
    networks:
      - jaguar
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -h localhost -U ${POSTGRES_USER} -d ${POSTGRES_DB}']
      interval: 5s
      timeout: 5s
      retries: 10

  qdrant:
    image: qdrant/qdrant:latest
    container_name: jaguar-qdrant
    restart: unless-stopped
    volumes:
      - qdrant_storage:/qdrant/storage
    networks:
      - jaguar
    environment:
      - QDRANT__SERVICE__HTTP_PORT=6333

  n8n:
    image: n8nio/n8n:latest
    container_name: jaguar-n8n
    restart: unless-stopped
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - N8N_USER_MANAGEMENT_JWT_SECRET=${N8N_USER_MANAGEMENT_JWT_SECRET}
      - N8N_HOST=n8n.thespatialnetwork.net
      - N8N_PROTOCOL=https
      - N8N_PORT=443
      - WEBHOOK_URL=https://n8n.thespatialnetwork.net
      - N8N_DIAGNOSTICS_ENABLED=false
      - N8N_PERSONALIZATION_ENABLED=false
      - N8N_RUNNERS_ENABLED=true
    volumes:
      - n8n_storage:/home/node/.n8n
      - ./workflows:/opt/n8n/workflows
    networks:
      - jaguar
    depends_on:
      postgres:
        condition: service_healthy

  openwebui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: jaguar-openwebui
    restart: unless-stopped
    environment:
      - WEBUI_NAME=Jaguar AGI
      - WEBUI_URL=https://ai.thespatialnetwork.net
      - ENABLE_SIGNUP=false
      - DEFAULT_USER_ROLE=user
    volumes:
      - ./openwebui_data:/app/backend/data
      - ./openwebui_n8n_pipe.py:/app/backend/data/functions/n8n_pipe.py
    networks:
      - jaguar
```

## 🌐 Step 4: Caddy Configuration

Create `/opt/jaguar-agi/Caddyfile`:

```
n8n.thespatialnetwork.net {
    reverse_proxy jaguar-n8n:5678
    
    header {
        # Security headers
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
    }
    
    # Enable compression
    encode gzip
    
    # Logging
    log {
        output file /var/log/caddy/n8n.log
        format json
    }
}

ai.thespatialnetwork.net {
    reverse_proxy jaguar-openwebui:8080
    
    header {
        # Security headers
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
    }
    
    # Enable compression
    encode gzip
    
    # Logging
    log {
        output file /var/log/caddy/openwebui.log
        format json
    }
}
```

## 🔐 Step 5: Environment Configuration

Create `/opt/jaguar-agi/.env.prod`:

```bash
# PostgreSQL Configuration
POSTGRES_USER=jaguar_user
POSTGRES_PASSWORD=your_secure_password_here
POSTGRES_DB=n8n

# N8N Configuration
N8N_ENCRYPTION_KEY=your_secure_encryption_key_here
N8N_USER_MANAGEMENT_JWT_SECRET=your_secure_jwt_secret_here

# Production URLs
PRODUCTION_N8N_URL=https://n8n.thespatialnetwork.net
PRODUCTION_OPENWEBUI_URL=https://ai.thespatialnetwork.net

# Qdrant Configuration
QDRANT_URL=http://jaguar-qdrant:6333
QDRANT_API_KEY=your_qdrant_api_key_here

# GitHub Configuration (optional)
GITHUB_TOKEN=your_github_token_here
GITHUB_ORG=The-Spatial-Network
```

## 🚀 Step 6: Deploy

```bash
# Navigate to deployment directory
cd /opt/jaguar-agi

# Set proper permissions
sudo chown -R $USER:$USER /opt/jaguar-agi
chmod 600 .env.prod

# Start services
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d

# Check status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

## 📝 Step 7: Configure N8N

1. **Access N8N**: Navigate to `https://n8n.thespatialnetwork.net`
2. **Setup Admin User**: Create your admin account
3. **Install LangChain Nodes**: 
   ```bash
   # Connect to n8n container
   docker exec -it jaguar-n8n /bin/sh
   
   # Install LangChain community nodes
   npm install @n8n/n8n-nodes-langchain
   
   # Restart n8n
   exit
   docker-compose -f docker-compose.prod.yml restart n8n
   ```

4. **Import Workflow**: Import the `Jaguar_AGI_Production_Workflow.json`
5. **Configure Credentials**: Set up Ollama, Qdrant, and other credentials

## 🔗 Step 8: Configure OpenWebUI

1. **Access OpenWebUI**: Navigate to `https://ai.thespatialnetwork.net`
2. **Setup Admin Account**: Create your admin account
3. **Install Pipe Function**: 
   - Go to Admin Panel → Functions
   - Create new function with ID `n8n_pipe`
   - Copy content from `openwebui_n8n_pipe.py`
   - Configure valves:
     - `n8n_url`: `https://n8n.thespatialnetwork.net/webhook/jaguar-agent`
     - Other settings as needed

## 🧪 Step 9: Test Integration

1. **Test N8N Workflow**:
   ```bash
   curl -X POST https://n8n.thespatialnetwork.net/webhook/jaguar-agent \
     -H "Content-Type: application/json" \
     -d '{"chatInput": "Hello Jaguar, what can you do?"}'
   ```

2. **Test OpenWebUI Integration**:
   - Create a new chat in OpenWebUI
   - Select the Jaguar model
   - Send a test message

## 🔧 Step 10: Production Optimizations

### Performance Tuning
```bash
# Increase file limits
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# Optimize Docker
echo '{"log-driver": "json-file", "log-opts": {"max-size": "10m", "max-file": "3"}}' > /etc/docker/daemon.json
systemctl restart docker
```

### Monitoring Setup
```bash
# Install monitoring tools
docker run -d --name=cadvisor \
  --restart=unless-stopped \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  --name=cadvisor \
  gcr.io/cadvisor/cadvisor:latest
```

### Backup Strategy
```bash
# Create backup script
cat > /opt/jaguar-agi/backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/backups/jaguar-agi"

mkdir -p $BACKUP_DIR

# Backup PostgreSQL
docker exec jaguar-postgres pg_dump -U jaguar_user n8n > $BACKUP_DIR/postgres_$DATE.sql

# Backup N8N data
docker run --rm -v n8n_storage:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/n8n_data_$DATE.tar.gz -C /data .

# Backup Qdrant data
docker run --rm -v qdrant_storage:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/qdrant_data_$DATE.tar.gz -C /data .

# Clean old backups (keep last 7 days)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
EOF

chmod +x /opt/jaguar-agi/backup.sh

# Add to crontab
echo "0 2 * * * /opt/jaguar-agi/backup.sh" | crontab -
```

## 🚨 Troubleshooting

### Common Issues

1. **SSL Certificate Issues**:
   ```bash
   # Check Caddy logs
   docker logs jaguar-caddy
   
   # Manually request certificate
   docker exec jaguar-caddy caddy reload --config /etc/caddy/Caddyfile
   ```

2. **N8N Connection Issues**:
   ```bash
   # Check n8n logs
   docker logs jaguar-n8n
   
   # Verify database connection
   docker exec jaguar-postgres psql -U jaguar_user -d n8n -c "\dt"
   ```

3. **OpenWebUI Function Issues**:
   ```bash
   # Check OpenWebUI logs
   docker logs jaguar-openwebui
   
   # Verify function installation
   # Check Admin Panel → Functions
   ```

## 📊 Monitoring URLs

- **N8N**: https://n8n.thespatialnetwork.net
- **OpenWebUI**: https://ai.thespatialnetwork.net
- **cAdvisor**: http://your-server-ip:8080
- **Caddy Admin**: https://your-server-ip:2019

## 🎯 Next Steps

1. Deploy to Digital Ocean using this guide
2. Test the integration between n8n and OpenWebUI
3. Configure additional AI models and tools
4. Set up monitoring and alerting
5. Implement backup and disaster recovery
6. Scale horizontally as needed

---

**🐆 Jaguar AGI Production Deployment**
*"Guiding the evolution of agents with natural wisdom"*

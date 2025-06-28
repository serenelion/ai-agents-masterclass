# GitHub Secrets Setup for CI/CD Pipeline

This guide will help you set up the required GitHub secrets and Digital Ocean configuration for the automated deployment pipeline.

## Required GitHub Secrets

You need to configure the following secrets in your GitHub repository:

### 1. Digital Ocean Access Token
- **Secret Name**: `DIGITALOCEAN_ACCESS_TOKEN`
- **Description**: API token for Digital Ocean CLI access
- **How to get it**:
  1. Go to [Digital Ocean API Tokens](https://cloud.digitalocean.com/account/api/tokens)
  2. Click "Generate New Token"
  3. Name it "GitHub Actions CI/CD"
  4. Select "Write" scope
  5. Copy the generated token

### 2. Droplet Connection Details
- **Secret Name**: `DROPLET_IP`
- **Value**: The public IP address of your droplet (504791828)
- **How to get it**: 
  ```bash
  doctl compute droplet list --format "ID,Name,PublicIPv4" | grep 504791828
  ```

- **Secret Name**: `DROPLET_USER`
- **Value**: The username for SSH access (usually `root` or `ubuntu`)

### 3. SSH Private Key
- **Secret Name**: `SSH_PRIVATE_KEY`
- **Description**: Private SSH key for accessing your droplet
- **How to generate**:
  ```bash
  # Generate a new SSH key pair (if you don't have one)
  ssh-keygen -t rsa -b 4096 -C "github-actions@yourdomain.com" -f ~/.ssh/github_actions_key
  
  # Copy the private key content (this goes in the GitHub secret)
  cat ~/.ssh/github_actions_key
  
  # Copy the public key to your droplet
  ssh-copy-id -i ~/.ssh/github_actions_key.pub user@your_droplet_ip
  ```

### 4. Database and Security Secrets
Generate secure passwords and keys for your production environment:

```bash
# Generate secure passwords (run these commands locally)
openssl rand -base64 32  # Use for POSTGRES_PASSWORD
openssl rand -base64 32  # Use for N8N_ENCRYPTION_KEY  
openssl rand -base64 32  # Use for N8N_USER_MANAGEMENT_JWT_SECRET
```

- **Secret Name**: `POSTGRES_PASSWORD`
- **Value**: Secure password for PostgreSQL database

- **Secret Name**: `N8N_ENCRYPTION_KEY`
- **Value**: 32+ character encryption key for n8n

- **Secret Name**: `N8N_USER_MANAGEMENT_JWT_SECRET`
- **Value**: 32+ character JWT secret for n8n user management

## Setting Up GitHub Secrets

1. Go to your GitHub repository
2. Click on "Settings" tab
3. In the left sidebar, click "Secrets and variables" → "Actions"
4. Click "New repository secret"
5. Add each secret with the name and value specified above

## Digital Ocean CLI Setup (Local Development)

If you want to manage your droplet locally, install and configure doctl:

```bash
# Install doctl (macOS)
brew install doctl

# Install doctl (Linux)
cd ~
wget https://github.com/digitalocean/doctl/releases/download/v1.101.0/doctl-1.101.0-linux-amd64.tar.gz
tar xf doctl-1.101.0-linux-amd64.tar.gz
sudo mv doctl /usr/local/bin

# Authenticate with Digital Ocean
doctl auth init

# Verify your droplet
doctl compute droplet list --format "ID,Name,PublicIPv4,Status"
```

## Droplet Preparation

Ensure your Digital Ocean droplet is properly configured:

### 1. SSH Access
```bash
# Test SSH access to your droplet
ssh user@your_droplet_ip

# If using a custom SSH key, test with:
ssh -i ~/.ssh/github_actions_key user@your_droplet_ip
```

### 2. Basic Server Setup
```bash
# Update the system
sudo apt update && sudo apt upgrade -y

# Install basic tools
sudo apt install -y curl wget git unzip

# Create a non-root user (if using root)
sudo adduser deploy
sudo usermod -aG sudo deploy
sudo usermod -aG docker deploy  # Will be created when Docker is installed
```

### 3. Firewall Configuration
```bash
# Configure UFW firewall
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
```

## DNS Configuration

Configure your DNS records to point to your droplet:

```
Type: A
Name: n8n.thespatialnetwork.net
Value: YOUR_DROPLET_IP
TTL: 300

Type: A  
Name: ai.thespatialnetwork.net
Value: YOUR_DROPLET_IP
TTL: 300
```

## Testing the Setup

### 1. Test GitHub Actions Workflow
1. Push a commit to the main branch
2. Go to GitHub → Actions tab
3. Watch the deployment workflow run
4. Check for any errors in the logs

### 2. Manual Deployment Test
You can also test the deployment manually:

```bash
# Clone the repository on your droplet
ssh user@your_droplet_ip
git clone https://github.com/serenelion/ai-agents-masterclass.git
cd ai-agents-masterclass/jaguar-local/production

# Run the deployment script
chmod +x deploy.sh
./deploy.sh
```

### 3. Verify Services
After deployment, verify that services are running:

```bash
# Check container status
docker-compose -f /opt/jaguar-agi/docker-compose.prod.yml ps

# Check logs
docker-compose -f /opt/jaguar-agi/docker-compose.prod.yml logs -f

# Test endpoints
curl -k https://n8n.thespatialnetwork.net
curl -k https://ai.thespatialnetwork.net
```

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Verify the droplet IP is correct
   - Check that the SSH key is properly configured
   - Ensure the droplet is running

2. **Docker Installation Failed**
   - The workflow will automatically install Docker
   - If it fails, manually install Docker on the droplet

3. **DNS Not Resolving**
   - DNS propagation can take up to 24 hours
   - Test with the droplet IP directly first
   - Use `dig` or `nslookup` to verify DNS records

4. **SSL Certificate Issues**
   - Caddy automatically handles SSL certificates
   - Ensure DNS is pointing to the correct IP
   - Check Caddy logs: `docker logs jaguar-caddy`

### Useful Commands

```bash
# View deployment logs
ssh user@droplet_ip "cd /opt/jaguar-agi && docker-compose -f docker-compose.prod.yml logs -f"

# Restart services
ssh user@droplet_ip "cd /opt/jaguar-agi && docker-compose -f docker-compose.prod.yml restart"

# Update deployment
ssh user@droplet_ip "cd /opt/jaguar-agi && docker-compose -f docker-compose.prod.yml pull && docker-compose -f docker-compose.prod.yml up -d"

# Check system resources
ssh user@droplet_ip "htop"
ssh user@droplet_ip "df -h"
ssh user@droplet_ip "free -h"
```

## Security Best Practices

1. **Use a non-root user** for deployments when possible
2. **Regularly update** your droplet and Docker images
3. **Monitor logs** for suspicious activity
4. **Backup your data** regularly
5. **Use strong passwords** for all secrets
6. **Limit SSH access** to specific IP addresses if possible
7. **Enable fail2ban** to prevent brute force attacks

## Next Steps

After setting up the CI/CD pipeline:

1. **Test the deployment** by pushing a commit to main
2. **Access n8n** at https://n8n.thespatialnetwork.net and create an admin account
3. **Import workflows** from the production directory
4. **Access OpenWebUI** at https://ai.thespatialnetwork.net
5. **Set up monitoring** and alerting for your services
6. **Configure backups** for your data

## Support

If you encounter issues:
1. Check the GitHub Actions logs for detailed error messages
2. SSH into your droplet and check Docker logs
3. Verify all secrets are correctly configured
4. Ensure DNS records are properly set up

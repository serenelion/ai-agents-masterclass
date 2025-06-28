# GitHub Secrets Setup for Jaguar AGI CI/CD

## 🔐 Required GitHub Secrets

To enable automatic deployment to Digital Ocean, you need to configure these secrets in your GitHub repository:

### 1. Navigate to Repository Settings
1. Go to https://github.com/serenelion/ai-agents-masterclass
2. Click on **Settings** tab
3. Click on **Secrets and variables** → **Actions**
4. Click **New repository secret**

### 2. Required Secrets

#### `DIGITALOCEAN_ACCESS_TOKEN`
- **Description**: Digital Ocean API token for managing droplets
- **How to get**:
  1. Go to https://cloud.digitalocean.com/account/api/tokens
  2. Click **Generate New Token**
  3. Name: `Jaguar AGI CI/CD`
  4. Scopes: **Read** and **Write**
  5. Copy the generated token
- **Value**: Paste your Digital Ocean API token

#### `DROPLET_SSH_KEY`
- **Description**: Private SSH key for accessing your droplet
- **How to get**:
  1. **Option A - Use existing key**:
     ```bash
     # If you have an existing SSH key
     cat ~/.ssh/id_rsa
     ```
  
  2. **Option B - Generate new key**:
     ```bash
     # Generate new SSH key pair
     ssh-keygen -t rsa -b 4096 -C "jaguar-agi-deploy" -f ~/.ssh/jaguar_deploy
     
     # Display private key (for GitHub secret)
     cat ~/.ssh/jaguar_deploy
     
     # Display public key (to add to droplet)
     cat ~/.ssh/jaguar_deploy.pub
     ```

- **Value**: Paste the **private key** content (including `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----`)

### 3. Add SSH Key to Digital Ocean Droplet

After creating the SSH key, you need to add the **public key** to your droplet:

#### Method 1: Using Digital Ocean Console
1. Go to https://cloud.digitalocean.com/droplets/504791828
2. Click **Console** to open web terminal
3. Run these commands:
   ```bash
   # Create .ssh directory if it doesn't exist
   mkdir -p ~/.ssh
   
   # Add your public key (replace with your actual public key)
   echo "ssh-rsa AAAAB3NzaC1yc2EAAAA... your-public-key-here" >> ~/.ssh/authorized_keys
   
   # Set proper permissions
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```

#### Method 2: Using SSH (if you already have access)
```bash
# Copy public key to droplet
ssh-copy-id -i ~/.ssh/jaguar_deploy.pub root@YOUR_DROPLET_IP

# Or manually add it
cat ~/.ssh/jaguar_deploy.pub | ssh root@YOUR_DROPLET_IP "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### 4. Test SSH Connection

Test that GitHub Actions can connect to your droplet:

```bash
# Test SSH connection with your private key
ssh -i ~/.ssh/jaguar_deploy root@YOUR_DROPLET_IP "echo 'Connection successful'"
```

### 5. Verify Droplet Configuration

Make sure your droplet is properly configured:

```bash
# Connect to your droplet
ssh root@YOUR_DROPLET_IP

# Check if Docker is installed
docker --version

# Check if Docker Compose is installed
docker-compose --version

# If not installed, run:
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

## 🚀 Triggering Deployments

Once secrets are configured, deployments will trigger automatically:

### Automatic Triggers
- **Push to main branch**: Direct pushes to main branch
- **Merged Pull Request**: When a PR is merged into main branch
- **File Changes**: Only when files in `jaguar-local/` directory change

### Manual Trigger
You can also trigger deployments manually:
1. Go to **Actions** tab in your repository
2. Select **Deploy Jaguar AGI to Production** workflow
3. Click **Run workflow**
4. Select **main** branch
5. Click **Run workflow**

## 📊 Monitoring Deployments

### GitHub Actions
- View deployment progress: https://github.com/serenelion/ai-agents-masterclass/actions
- Check logs for each deployment step
- Monitor success/failure status

### Digital Ocean Droplet
```bash
# Connect to droplet
ssh root@YOUR_DROPLET_IP

# Check deployment status
cd /opt/jaguar-agi
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Check service health
curl http://localhost:5678/healthz  # n8n
curl http://localhost:8080/health   # OpenWebUI
```

## 🔧 Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   ```bash
   # Check if SSH key is properly formatted
   ssh-keygen -l -f ~/.ssh/jaguar_deploy
   
   # Test connection manually
   ssh -i ~/.ssh/jaguar_deploy -v root@YOUR_DROPLET_IP
   ```

2. **Digital Ocean API Issues**
   ```bash
   # Test API token
   curl -X GET \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_DO_TOKEN" \
     "https://api.digitalocean.com/v2/droplets/504791828"
   ```

3. **Deployment Failures**
   - Check GitHub Actions logs
   - Verify droplet has enough disk space
   - Check Docker service status on droplet

### Debug Commands

```bash
# On droplet - check system resources
df -h                    # Disk usage
free -h                  # Memory usage
docker system df         # Docker usage
docker system prune -f   # Clean up Docker

# Check service logs
docker logs jaguar-n8n
docker logs jaguar-openwebui
docker logs jaguar-caddy
```

## 🔐 Security Best Practices

1. **Rotate SSH Keys Regularly**
   - Generate new SSH keys every 90 days
   - Update GitHub secrets with new keys
   - Remove old keys from droplet

2. **Monitor Access Logs**
   ```bash
   # Check SSH access logs
   tail -f /var/log/auth.log
   
   # Check deployment logs
   tail -f /var/log/caddy/*.log
   ```

3. **Use Least Privilege**
   - Digital Ocean token should only have necessary permissions
   - Consider using a dedicated deployment user instead of root

4. **Enable Firewall**
   ```bash
   # Configure UFW firewall
   ufw allow ssh
   ufw allow 80
   ufw allow 443
   ufw enable
   ```

## 📞 Support

If you encounter issues:
1. Check GitHub Actions logs first
2. Verify all secrets are properly configured
3. Test SSH connection manually
4. Check droplet system resources
5. Review deployment logs on the droplet

---

**🐆 Jaguar AGI CI/CD Pipeline**
*Automated deployment to Digital Ocean*

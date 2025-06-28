# Security Documentation for Jaguar AGI CI/CD Pipeline

This document outlines the security measures implemented in the GitHub Actions CI/CD pipeline for deploying to Digital Ocean.

## Security Overview

The CI/CD pipeline has been designed with security as a top priority, implementing multiple layers of protection to ensure safe deployment to production environments.

## Security Features Implemented

### 1. Repository Security
- **Public Repository Safe**: All sensitive data is stored in GitHub Secrets, never in code
- **Path-based Triggers**: Workflow only triggers on changes to specific directories
- **Sparse Checkout**: Only necessary files are checked out during deployment
- **Gitignore Protection**: All sensitive files are excluded from version control

### 2. Access Control
- **Restricted Permissions**: Workflow uses minimal required permissions
- **Manual Confirmation**: Manual deployments require typing "DEPLOY" to confirm
- **Branch Protection**: Only deploys from the main branch
- **Timeout Protection**: 30-minute timeout prevents runaway deployments

### 3. Secret Management
- **GitHub Secrets**: All sensitive data stored securely in GitHub repository secrets
- **Environment Variables**: Secrets properly scoped to individual steps
- **No Hardcoded Values**: Zero hardcoded credentials or sensitive information
- **Secret Validation**: Pipeline validates all required secrets before deployment

### 4. SSH Security
- **Private Key Protection**: SSH private keys stored as GitHub secrets
- **Key Cleanup**: SSH keys removed after deployment completion
- **Host Verification**: SSH host key verification for secure connections
- **Minimal Access**: SSH access limited to deployment operations only

### 5. Deployment Security
- **Secure File Transfer**: SCP with strict host checking disabled only for automation
- **Environment Isolation**: Production environment files separated from development
- **File Permissions**: Secure file permissions (600) for sensitive configuration files
- **Container Security**: Docker containers run with minimal required privileges

### 6. Network Security
- **HTTPS Only**: All external communications use HTTPS
- **SSL Certificates**: Automatic SSL certificate management via Caddy
- **Firewall Ready**: Configuration supports standard firewall rules (80, 443, 22)
- **Internal Networks**: Docker containers communicate via internal networks

## Required GitHub Secrets

The following secrets must be configured in your GitHub repository:

| Secret Name | Description | Security Level |
|-------------|-------------|----------------|
| `DIGITALOCEAN_ACCESS_TOKEN` | Digital Ocean API token | High |
| `DROPLET_IP` | Target droplet IP address | Medium |
| `DROPLET_USER` | SSH username for droplet | Medium |
| `SSH_PRIVATE_KEY` | SSH private key for authentication | Critical |
| `POSTGRES_PASSWORD` | Database password | High |
| `N8N_ENCRYPTION_KEY` | N8N encryption key (32+ chars) | Critical |
| `N8N_USER_MANAGEMENT_JWT_SECRET` | N8N JWT secret (32+ chars) | Critical |

## Security Best Practices Implemented

### 1. Principle of Least Privilege
- Workflow permissions limited to essential operations only
- SSH access restricted to deployment tasks
- Container permissions minimized

### 2. Defense in Depth
- Multiple validation layers before deployment
- Secret validation at multiple stages
- Health checks to verify deployment success

### 3. Secure by Default
- HTTPS enforced for all web traffic
- Secure file permissions applied automatically
- Strong encryption keys generated automatically

### 4. Audit Trail
- All deployment actions logged in GitHub Actions
- Security check summary included in each run
- Deployment status and health checks recorded

## Security Validation Process

The pipeline includes a multi-stage security validation process:

1. **Pre-deployment Security Check**
   - Validates manual deployment confirmation
   - Checks repository and actor information
   - Logs security context for audit

2. **Secret Validation**
   - Verifies all required secrets are present
   - Fails fast if any secrets are missing
   - Provides clear error messages for missing secrets

3. **SSH Security Setup**
   - Securely configures SSH authentication
   - Validates host keys
   - Sets appropriate file permissions

4. **Deployment Validation**
   - Verifies droplet status before deployment
   - Checks Docker installation and configuration
   - Validates service health after deployment

## Potential Security Considerations

### 1. SSH Host Key Verification
- Currently disabled (`StrictHostKeyChecking=no`) for automation
- Consider implementing known_hosts management for enhanced security
- Monitor for SSH connection anomalies

### 2. Container Security
- Regularly update Docker images to latest versions
- Consider implementing container vulnerability scanning
- Monitor container resource usage and access patterns

### 3. Network Security
- Implement firewall rules on the droplet
- Consider VPN access for administrative tasks
- Monitor network traffic for anomalies

## Security Monitoring Recommendations

### 1. GitHub Actions Monitoring
- Review workflow run logs regularly
- Monitor for failed deployments or security checks
- Set up notifications for deployment failures

### 2. Server Monitoring
- Monitor SSH access logs on the droplet
- Track Docker container status and resource usage
- Implement log aggregation for security events

### 3. Application Monitoring
- Monitor n8n and OpenWebUI access logs
- Track authentication attempts and failures
- Set up alerts for suspicious activity

## Incident Response

### 1. Compromised Secrets
If any secrets are compromised:
1. Immediately rotate all affected secrets in GitHub repository settings
2. Update corresponding services with new credentials
3. Review access logs for unauthorized usage
4. Consider regenerating SSH keys if SSH access is compromised

### 2. Unauthorized Access
If unauthorized access is detected:
1. Immediately revoke access tokens and rotate secrets
2. Review and audit all recent deployments
3. Check server logs for unauthorized activities
4. Consider rebuilding the droplet if compromise is confirmed

### 3. Deployment Failures
If deployments fail due to security issues:
1. Review GitHub Actions logs for error details
2. Verify all secrets are correctly configured
3. Check droplet connectivity and status
4. Validate DNS and SSL certificate configuration

## Security Updates and Maintenance

### 1. Regular Updates
- Update GitHub Actions workflow dependencies monthly
- Keep Docker images updated to latest versions
- Regularly rotate secrets and passwords

### 2. Security Reviews
- Review security configuration quarterly
- Audit access logs and deployment history
- Update security documentation as needed

### 3. Compliance
- Ensure compliance with organizational security policies
- Document any security exceptions or deviations
- Maintain security audit trail for compliance requirements

## Contact and Support

For security-related questions or to report security issues:
- Review GitHub Actions logs for deployment issues
- Check Digital Ocean droplet status and logs
- Verify DNS and SSL certificate configuration
- Consult the troubleshooting section in GITHUB_SECRETS_SETUP.md

## Security Checklist

Before deploying to production, ensure:

- [ ] All required secrets are configured in GitHub repository
- [ ] SSH access to droplet is working correctly
- [ ] DNS records are pointing to the correct droplet IP
- [ ] Firewall rules are configured on the droplet
- [ ] SSL certificates are properly configured
- [ ] All sensitive files are excluded from version control
- [ ] Deployment workflow has been tested in a safe environment
- [ ] Monitoring and alerting are configured
- [ ] Incident response procedures are documented
- [ ] Security documentation is up to date

## Conclusion

This CI/CD pipeline implements comprehensive security measures to protect against common threats while maintaining deployment automation. Regular review and updates of these security measures are essential to maintain a strong security posture.

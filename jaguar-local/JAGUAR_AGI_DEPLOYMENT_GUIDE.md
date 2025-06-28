# Jaguar AGI Deployment Guide

## 🐆 Overview

This guide provides complete instructions for deploying the Jaguar AGI system, which consists of:

1. **OpenWebUI N8N Pipe Function** - Advanced pipe function for OpenWebUI integration
2. **Jaguar AGI Master Workflow** - Comprehensive n8n workflow with AGI capabilities

## 📋 Prerequisites

- N8N instance (local or hosted)
- OpenWebUI instance at https://ai.thespatialnetwork.net
- Ollama with Llama 3.1 model
- Qdrant vector database
- PostgreSQL database
- GitHub access (optional)

## 🚀 Part 1: Deploy OpenWebUI Pipe Function

### Step 1: Copy the Pipe Function

1. Navigate to https://ai.thespatialnetwork.net/admin/functions/edit?id=n8n_pipe
2. Copy the entire contents of `openwebui_n8n_pipe.py`
3. Paste it into the function editor
4. Save the function

### Step 2: Configure the Pipe Function

The pipe function includes these configurable valves:

#### Core N8N Configuration
- **n8n_url**: Your n8n webhook URL (default: `https://n8n.thespatialnetwork.net/webhook/jaguar-agent`)
- **n8n_bearer_token**: Bearer token for n8n authentication
- **n8n_api_url**: N8N API base URL for workflow management
- **n8n_api_key**: N8N API key for workflow CRUD operations

#### GitHub Integration
- **github_token**: GitHub token for repository operations
- **github_org**: Default GitHub organization (default: `The-Spatial-Network`)

#### AGI Features (All enabled by default)
- **enable_rag**: RAG queries to masterclass knowledge base
- **enable_github_operations**: GitHub repository operations
- **enable_workflow_generation**: Dynamic N8N workflow generation
- **enable_self_improvement**: Self-improvement and learning capabilities
- **enable_code_execution**: Code execution and testing
- **enable_documentation_sync**: Real-time documentation synchronization
- **enable_multi_agent_coordination**: Multi-agent coordination
- **enable_learning_from_interactions**: Learn from user interactions

#### Advanced Settings
- **creativity_level**: Creativity level for responses (0.0-1.0, default: 0.7)
- **max_iterations**: Maximum iterations for complex tasks (default: 5)
- **timeout**: Request timeout in seconds (default: 120)
- **enable_debug_logging**: Enable detailed debug logging

## 🔧 Part 2: Deploy N8N Workflow

### Step 1: Import the Workflow

1. Open your n8n instance
2. Go to **Workflows** → **Import from File**
3. Upload `Jaguar_AGI_Master_Workflow.json`
4. The workflow will be imported with all nodes and connections

### Step 2: Configure Credentials

You'll need to set up these credentials in n8n:

#### Required Credentials
1. **Ollama API** (`ollama-credentials`)
   - Base URL: `http://jaguar-ollama:11434` (or your Ollama URL)

2. **Qdrant API** (`qdrant-credentials`)
   - URL: `http://jaguar-qdrant:6333` (or your Qdrant URL)
   - API Key: Your Qdrant API key

3. **Postgres** (`postgres-credentials`)
   - Host: `postgres` (or your PostgreSQL host)
   - Database: `n8n`
   - Username: From your `.env` file
   - Password: From your `.env` file

#### Optional Credentials
4. **GitHub API** (`github-api-credentials`)
   - Token: Your GitHub personal access token

5. **N8N API** (`n8n-api-credentials`)
   - API Key: Your n8n API key

### Step 3: Configure Vector Collections

Ensure these Qdrant collections exist:
- `masterclass_knowledge` - For AI agents masterclass content
- `documentation_knowledge` - For n8n and OpenWebUI documentation

### Step 4: Activate the Workflow

1. Open the imported workflow
2. Click **Active** toggle to enable it
3. Note the webhook URL (will be something like: `https://your-n8n.com/webhook/jaguar-agent`)

## 🔗 Part 3: Connect the Components

### Update Pipe Function Configuration

1. In OpenWebUI, go to the pipe function settings
2. Update the **n8n_url** valve to match your n8n webhook URL
3. Add any authentication tokens if required
4. Save the configuration

### Test the Integration

1. In OpenWebUI, start a new chat with the Jaguar model
2. Send a test message like: "Hello Jaguar, what can you do?"
3. You should see status updates and receive a comprehensive response

## 🧠 AGI Capabilities

The Jaguar AGI system includes these advanced features:

### 🔍 Intelligent Request Analysis
- Automatically analyzes request complexity
- Determines required capabilities
- Estimates processing time
- Routes requests to appropriate handlers

### 📚 Knowledge Access
- **Masterclass Knowledge**: Complete AI agents masterclass with 11 lessons
- **Documentation Access**: Latest n8n and OpenWebUI documentation
- **Real-time Updates**: Continuously synced platform documentation

### 🛠️ Dynamic Operations
- **Workflow Generation**: Create n8n workflows on demand
- **GitHub Operations**: Full repository lifecycle management
- **Code Execution**: Run and test code in multiple languages
- **Documentation Sync**: Generate and maintain documentation

### 🧠 Learning & Adaptation
- **Session Context**: Maintains conversation context
- **Learning from Interactions**: Adapts based on user preferences
- **Self-Improvement**: Continuously improves responses
- **Multi-Agent Coordination**: Orchestrates complex workflows

## 📊 Monitoring & Debugging

### Enable Debug Mode
Set `enable_debug_logging: true` in the pipe function to see:
- Session information
- Complexity analysis
- Capability usage
- Performance metrics
- AGI version information

### Status Indicators
The system provides real-time status updates:
- 🐆 Jaguar AGI is awakening...
- 🧠 Analyzing request complexity
- 🔗 Connecting to Jaguar AGI workflow...
- 🚀 Executing Jaguar AGI workflow...
- 🔄 Processing AGI response...
- ✅ Jaguar AGI has completed the task

### Error Handling
Comprehensive error handling with:
- Detailed error messages
- Troubleshooting steps
- Session information
- Recovery suggestions

## 🔧 Customization

### Adding New Tools
To add new tools to the AGI agent:

1. Create a new sub-workflow in n8n
2. Add a new tool node in the main workflow
3. Connect it to the Jaguar AGI Agent
4. Update the system prompt if needed

### Modifying System Prompt
The system prompt can be customized in the "Jaguar AGI System Prompt" node to:
- Change personality
- Add new capabilities
- Modify response style
- Include domain-specific knowledge

### Extending Capabilities
Add new capabilities by:
- Creating new valve options in the pipe function
- Adding corresponding logic in the workflow
- Updating the complexity analysis
- Adding new tool integrations

## 🚨 Troubleshooting

### Common Issues

1. **Connection Timeout**
   - Check n8n webhook URL
   - Verify network connectivity
   - Increase timeout value

2. **Authentication Errors**
   - Verify bearer tokens
   - Check API keys
   - Ensure credentials are properly configured

3. **Vector Store Issues**
   - Verify Qdrant collections exist
   - Check embedding model availability
   - Ensure proper indexing

4. **Memory Issues**
   - Check PostgreSQL connection
   - Verify session ID handling
   - Clear old sessions if needed

### Performance Optimization

1. **Adjust Creativity Level**: Lower values (0.3-0.5) for more focused responses
2. **Limit Iterations**: Reduce max_iterations for faster responses
3. **Optimize Vector Search**: Adjust topK values for knowledge tools
4. **Cache Management**: Implement caching for frequently accessed data

## 📈 Scaling Considerations

### Production Deployment
- Use dedicated servers for each component
- Implement load balancing for n8n
- Set up monitoring and alerting
- Configure backup strategies

### Resource Requirements
- **CPU**: 4+ cores recommended
- **RAM**: 8GB+ for full AGI capabilities
- **Storage**: SSD recommended for vector databases
- **Network**: Low latency between components

## 🔐 Security

### Best Practices
- Use HTTPS for all communications
- Implement proper authentication
- Regularly rotate API keys
- Monitor access logs
- Limit webhook access

### Data Privacy
- Session data is stored temporarily
- Learning data can be disabled
- Implement data retention policies
- Ensure GDPR compliance if applicable

## 📞 Support

For issues or questions:
- Check the troubleshooting section
- Review n8n and OpenWebUI documentation
- Contact The Spatial Network support
- Submit issues to the GitHub repository

## 🎯 Next Steps

After successful deployment:
1. Test all AGI capabilities
2. Customize the system prompt
3. Add domain-specific knowledge
4. Create custom workflows
5. Monitor performance and optimize
6. Scale based on usage patterns

---

**🐆 Jaguar AGI v2.0 - The Spatial Network**

*"Guiding the evolution of agents with natural wisdom"*

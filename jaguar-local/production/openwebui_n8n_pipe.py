"""
title: Jaguar N8N AGI Pipe Function
author: The Spatial Network
author_url: https://thespatialnetwork.net
version: 2.0.0

Advanced OpenWebUI Pipe Function for Jaguar AI Developer Agent
Enhanced with dynamic workflow generation, self-improvement capabilities,
and comprehensive AGI features for The Spatial Network ecosystem.
"""

from typing import Optional, Callable, Awaitable, Dict, List, Any
from pydantic import BaseModel, Field
import os
import time
import requests
import json
import asyncio
from datetime import datetime, timezone

def extract_event_info(event_emitter) -> tuple[Optional[str], Optional[str]]:
    """Extract chat and message IDs from event emitter for session tracking."""
    if not event_emitter or not event_emitter.__closure__:
        return None, None
    for cell in event_emitter.__closure__:
        if isinstance(request_info := cell.cell_contents, dict):
            chat_id = request_info.get("chat_id")
            message_id = request_info.get("message_id")
            return chat_id, message_id
    return None, None

class Pipe:
    class Valves(BaseModel):
        # Core N8N Configuration
        n8n_url: str = Field(
            default="https://n8n.thespatialnetwork.net/webhook/jaguar-agent",
            description="N8N webhook URL for Jaguar workflow"
        )
        n8n_bearer_token: str = Field(
            default="",
            description="Bearer token for N8N authentication"
        )
        
        # API Configuration
        n8n_api_url: str = Field(
            default="https://n8n.thespatialnetwork.net/api/v1",
            description="N8N API base URL for workflow management"
        )
        n8n_api_key: str = Field(
            default="",
            description="N8N API key for workflow CRUD operations"
        )
        
        # GitHub Integration
        github_token: str = Field(
            default="",
            description="GitHub token for repository operations"
        )
        github_org: str = Field(
            default="The-Spatial-Network",
            description="Default GitHub organization"
        )
        
        # Request/Response Configuration
        input_field: str = Field(default="chatInput")
        response_field: str = Field(default="output")
        timeout: int = Field(default=120, description="Request timeout in seconds")
        
        # Status and Monitoring
        emit_interval: float = Field(
            default=1.5, description="Interval in seconds between status emissions"
        )
        enable_status_indicator: bool = Field(
            default=True, description="Enable or disable status indicator emissions"
        )
        enable_debug_logging: bool = Field(
            default=False, description="Enable detailed debug logging"
        )
        
        # AGI Features
        enable_rag: bool = Field(
            default=True, description="Enable RAG queries to masterclass knowledge base"
        )
        enable_github_operations: bool = Field(
            default=True, description="Enable GitHub repository operations"
        )
        enable_workflow_generation: bool = Field(
            default=True, description="Enable dynamic N8N workflow generation"
        )
        enable_self_improvement: bool = Field(
            default=True, description="Enable self-improvement and learning capabilities"
        )
        enable_code_execution: bool = Field(
            default=True, description="Enable code execution and testing"
        )
        enable_documentation_sync: bool = Field(
            default=True, description="Enable real-time documentation synchronization"
        )
        
        # Advanced AGI Settings
        creativity_level: float = Field(
            default=0.7, description="Creativity level for responses (0.0-1.0)"
        )
        max_iterations: int = Field(
            default=5, description="Maximum iterations for complex tasks"
        )
        enable_multi_agent_coordination: bool = Field(
            default=True, description="Enable coordination with other AI agents"
        )
        enable_learning_from_interactions: bool = Field(
            default=True, description="Learn and adapt from user interactions"
        )

    def __init__(self):
        self.type = "pipe"
        self.id = "jaguar_agi_pipe"
        self.name = "Jaguar AGI Developer Agent"
        self.valves = self.Valves()
        self.last_emit_time = 0
        self.session_context = {}
        self.learning_data = {}

    async def emit_status(
        self,
        __event_emitter__: Callable[[dict], Awaitable[None]],
        level: str,
        message: str,
        done: bool,
        progress: Optional[float] = None
    ):
        """Enhanced status emission with progress tracking."""
        current_time = time.time()
        if (
            __event_emitter__
            and self.valves.enable_status_indicator
            and (
                current_time - self.last_emit_time >= self.valves.emit_interval or done
            )
        ):
            status_data = {
                "type": "status",
                "data": {
                    "status": "complete" if done else "in_progress",
                    "level": level,
                    "description": message,
                    "done": done,
                    "timestamp": datetime.now(timezone.utc).isoformat()
                },
            }
            
            if progress is not None:
                status_data["data"]["progress"] = progress
                
            await __event_emitter__(status_data)
            self.last_emit_time = current_time

    def analyze_request_complexity(self, message: str) -> Dict[str, Any]:
        """Analyze request complexity and determine required capabilities."""
        complexity_indicators = {
            "workflow_creation": ["create workflow", "build workflow", "new workflow", "workflow for"],
            "github_operations": ["github", "repository", "repo", "commit", "pull request", "issue"],
            "code_generation": ["write code", "create function", "implement", "develop"],
            "documentation": ["document", "explain", "how to", "tutorial", "guide"],
            "debugging": ["debug", "fix", "error", "problem", "issue", "troubleshoot"],
            "optimization": ["optimize", "improve", "enhance", "better", "performance"],
            "learning": ["learn", "understand", "analyze", "study", "research"]
        }
        
        detected_capabilities = []
        complexity_score = 0
        
        message_lower = message.lower()
        
        for capability, keywords in complexity_indicators.items():
            if any(keyword in message_lower for keyword in keywords):
                detected_capabilities.append(capability)
                complexity_score += 1
        
        # Determine if multi-step processing is needed
        multi_step_indicators = ["and then", "after that", "next", "also", "additionally"]
        requires_multi_step = any(indicator in message_lower for indicator in multi_step_indicators)
        
        return {
            "capabilities": detected_capabilities,
            "complexity_score": complexity_score,
            "requires_multi_step": requires_multi_step,
            "estimated_duration": min(complexity_score * 15, 120)  # seconds
        }

    async def execute_n8n_workflow(
        self,
        payload: Dict[str, Any],
        __event_emitter__: Callable[[dict], Awaitable[None]]
    ) -> Dict[str, Any]:
        """Execute the main N8N workflow with enhanced error handling."""
        headers = {
            "Content-Type": "application/json",
            "User-Agent": "Jaguar-AGI-Agent/2.0"
        }
        
        if self.valves.n8n_bearer_token:
            headers["Authorization"] = f"Bearer {self.valves.n8n_bearer_token}"
        
        try:
            await self.emit_status(
                __event_emitter__, "info", "🔗 Connecting to Jaguar AGI workflow...", False, 0.1
            )
            
            response = requests.post(
                self.valves.n8n_url,
                json=payload,
                headers=headers,
                timeout=self.valves.timeout
            )
            
            if response.status_code == 200:
                response_data = response.json()
                
                if self.valves.enable_debug_logging:
                    await self.emit_status(
                        __event_emitter__, "debug", f"N8N Response: {json.dumps(response_data, indent=2)}", False
                    )
                
                return response_data
            else:
                error_msg = f"N8N API Error: {response.status_code} - {response.text}"
                await self.emit_status(__event_emitter__, "error", error_msg, False)
                raise Exception(error_msg)
                
        except requests.exceptions.Timeout:
            error_msg = "N8N workflow execution timed out"
            await self.emit_status(__event_emitter__, "error", error_msg, False)
            raise Exception(error_msg)
        except requests.exceptions.ConnectionError:
            error_msg = "Failed to connect to N8N workflow"
            await self.emit_status(__event_emitter__, "error", error_msg, False)
            raise Exception(error_msg)

    async def handle_learning_and_adaptation(
        self,
        chat_id: str,
        user_message: str,
        response: str,
        __event_emitter__: Callable[[dict], Awaitable[None]]
    ):
        """Handle learning from interactions and self-improvement."""
        if not self.valves.enable_learning_from_interactions:
            return
            
        # Store interaction data for learning
        if chat_id not in self.learning_data:
            self.learning_data[chat_id] = {
                "interactions": [],
                "preferences": {},
                "success_patterns": []
            }
        
        interaction = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "user_message": user_message,
            "response": response,
            "message_length": len(user_message),
            "response_length": len(response)
        }
        
        self.learning_data[chat_id]["interactions"].append(interaction)
        
        # Keep only last 50 interactions per session
        if len(self.learning_data[chat_id]["interactions"]) > 50:
            self.learning_data[chat_id]["interactions"] = self.learning_data[chat_id]["interactions"][-50:]

    async def pipe(
        self,
        body: dict,
        __user__: Optional[dict] = None,
        __event_emitter__: Callable[[dict], Awaitable[None]] = None,
        __event_call__: Callable[[dict], Awaitable[dict]] = None,
    ) -> Optional[dict]:
        """Main pipe function with enhanced AGI capabilities."""
        
        # Initialize session tracking
        chat_id, message_id = extract_event_info(__event_emitter__)
        session_id = chat_id or f"session_{int(time.time())}"
        
        await self.emit_status(
            __event_emitter__, "info", "🐆 Jaguar AGI is awakening...", False, 0.05
        )
        
        messages = body.get("messages", [])
        
        if not messages:
            await self.emit_status(
                __event_emitter__,
                "error",
                "❌ No messages found in the request body",
                True
            )
            body["messages"].append({
                "role": "assistant",
                "content": "No messages found in the request body"
            })
            return body

        user_message = messages[-1]["content"]
        
        # Analyze request complexity
        complexity_analysis = self.analyze_request_complexity(user_message)
        
        await self.emit_status(
            __event_emitter__,
            "info",
            f"🧠 Analyzing request complexity: {complexity_analysis['complexity_score']}/7",
            False,
            0.15
        )
        
        try:
            # Prepare enhanced payload
            payload = {
                self.valves.input_field: user_message,
                "sessionId": session_id,
                "messageId": message_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "userInfo": __user__ or {},
                
                # AGI Feature Flags
                "enableRAG": self.valves.enable_rag,
                "enableGitHub": self.valves.enable_github_operations,
                "enableWorkflowGeneration": self.valves.enable_workflow_generation,
                "enableSelfImprovement": self.valves.enable_self_improvement,
                "enableCodeExecution": self.valves.enable_code_execution,
                "enableDocumentationSync": self.valves.enable_documentation_sync,
                "enableMultiAgentCoordination": self.valves.enable_multi_agent_coordination,
                
                # Complexity and Context
                "complexityAnalysis": complexity_analysis,
                "creativityLevel": self.valves.creativity_level,
                "maxIterations": self.valves.max_iterations,
                
                # Session Context
                "sessionContext": self.session_context.get(session_id, {}),
                "learningData": self.learning_data.get(session_id, {}),
                
                # Configuration
                "githubOrg": self.valves.github_org,
                "debugMode": self.valves.enable_debug_logging
            }
            
            await self.emit_status(
                __event_emitter__,
                "info",
                "🚀 Executing Jaguar AGI workflow...",
                False,
                0.3
            )
            
            # Execute main workflow
            response_data = await self.execute_n8n_workflow(payload, __event_emitter__)
            
            await self.emit_status(
                __event_emitter__,
                "info",
                "🔄 Processing AGI response...",
                False,
                0.8
            )
            
            # Extract response
            jaguar_response = response_data.get(self.valves.response_field, "")
            
            if not jaguar_response:
                # Fallback response extraction
                jaguar_response = (
                    response_data.get("result", "") or
                    response_data.get("message", "") or
                    str(response_data)
                )
            
            # Handle learning and adaptation
            await self.handle_learning_and_adaptation(
                session_id, user_message, jaguar_response, __event_emitter__
            )
            
            # Update session context
            if session_id not in self.session_context:
                self.session_context[session_id] = {
                    "created_at": datetime.now(timezone.utc).isoformat(),
                    "message_count": 0,
                    "capabilities_used": set()
                }
            
            self.session_context[session_id]["message_count"] += 1
            self.session_context[session_id]["last_activity"] = datetime.now(timezone.utc).isoformat()
            self.session_context[session_id]["capabilities_used"].update(complexity_analysis["capabilities"])
            
            await self.emit_status(
                __event_emitter__,
                "success",
                "✅ Jaguar AGI has completed the task with enhanced intelligence",
                True,
                1.0
            )
            
            # Add enhanced response with metadata
            enhanced_response = jaguar_response
            
            if self.valves.enable_debug_logging:
                enhanced_response += f"\n\n---\n**Debug Info:**\n- Session: {session_id}\n- Complexity: {complexity_analysis['complexity_score']}/7\n- Capabilities: {', '.join(complexity_analysis['capabilities'])}"
            
            body["messages"].append({
                "role": "assistant",
                "content": enhanced_response
            })
            
        except Exception as e:
            error_message = str(e)
            await self.emit_status(
                __event_emitter__,
                "error",
                f"❌ Jaguar AGI encountered an error: {error_message}",
                True
            )
            
            # Enhanced error response with troubleshooting
            error_response = f"""I encountered an error while processing your request: {error_message}

**Troubleshooting Steps:**
1. Ensure the Jaguar N8N workflow is running and accessible
2. Check network connectivity to {self.valves.n8n_url}
3. Verify authentication tokens are valid
4. Try simplifying your request if it's complex

**Technical Details:**
- Session ID: {session_id}
- Timestamp: {datetime.now(timezone.utc).isoformat()}
- Request Complexity: {complexity_analysis.get('complexity_score', 'Unknown')}

I'm continuously learning and improving. Please try again or contact The Spatial Network support."""
            
            body["messages"].append({
                "role": "assistant",
                "content": error_response
            })

        return body

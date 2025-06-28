"""
title: Jaguar N8N Pipe Function
author: The Spatial Network
author_url: https://thespatialnetwork.net
version: 1.0.0

This module defines a Pipe class that utilizes N8N for Jaguar AI Developer Agent
Enhanced with masterclass knowledge base integration and GitHub operations
"""

from typing import Optional, Callable, Awaitable
from pydantic import BaseModel, Field
import os
import time
import requests

def extract_event_info(event_emitter) -> tuple[Optional[str], Optional[str]]:
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
        n8n_url: str = Field(
            default="http://localhost:5678/webhook/jaguar-agent"
        )
        n8n_bearer_token: str = Field(default="")
        input_field: str = Field(default="chatInput")
        response_field: str = Field(default="output")
        emit_interval: float = Field(
            default=2.0, description="Interval in seconds between status emissions"
        )
        enable_status_indicator: bool = Field(
            default=True, description="Enable or disable status indicator emissions"
        )
        enable_rag: bool = Field(
            default=True, description="Enable RAG queries to masterclass knowledge base"
        )
        github_operations: bool = Field(
            default=True, description="Enable GitHub repository operations"
        )

    def __init__(self):
        self.type = "pipe"
        self.id = "jaguar_pipe"
        self.name = "Jaguar AI Developer Agent"
        self.valves = self.Valves()
        self.last_emit_time = 0
        pass

    async def emit_status(
        self,
        __event_emitter__: Callable[[dict], Awaitable[None]],
        level: str,
        message: str,
        done: bool,
    ):
        current_time = time.time()
        if (
            __event_emitter__
            and self.valves.enable_status_indicator
            and (
                current_time - self.last_emit_time >= self.valves.emit_interval or done
            )
        ):
            await __event_emitter__(
                {
                    "type": "status",
                    "data": {
                        "status": "complete" if done else "in_progress",
                        "level": level,
                        "description": message,
                        "done": done,
                    },
                }
            )
            self.last_emit_time = current_time

    async def pipe(
        self,
        body: dict,
        __user__: Optional[dict] = None,
        __event_emitter__: Callable[[dict], Awaitable[None]] = None,
        __event_call__: Callable[[dict], Awaitable[dict]] = None,
    ) -> Optional[dict]:
        await self.emit_status(
            __event_emitter__, "info", "🐆 Jaguar is processing your request...", False
        )
        chat_id, _ = extract_event_info(__event_emitter__)
        messages = body.get("messages", [])

        # Verify a message is available
        if messages:
            question = messages[-1]["content"]
            try:
                # Invoke Jaguar N8N workflow
                headers = {
                    "Content-Type": "application/json",
                }
                if self.valves.n8n_bearer_token:
                    headers["Authorization"] = f"Bearer {self.valves.n8n_bearer_token}"
                
                payload = {
                    "sessionId": f"{chat_id}",
                    "enableRAG": self.valves.enable_rag,
                    "enableGitHub": self.valves.github_operations
                }
                payload[self.valves.input_field] = question
                
                await self.emit_status(
                    __event_emitter__, "info", "🔗 Connecting to Jaguar workflow...", False
                )
                
                response = requests.post(
                    self.valves.n8n_url, json=payload, headers=headers, timeout=60
                )
                
                if response.status_code == 200:
                    response_data = response.json()
                    jaguar_response = response_data.get(self.valves.response_field, "")
                    
                    await self.emit_status(
                        __event_emitter__, "info", "✅ Jaguar has completed the task", True
                    )
                else:
                    raise Exception(f"Error: {response.status_code} - {response.text}")

                # Set assistant message with Jaguar's response
                body["messages"].append({"role": "assistant", "content": jaguar_response})
                
            except Exception as e:
                await self.emit_status(
                    __event_emitter__,
                    "error",
                    f"❌ Error during Jaguar execution: {str(e)}",
                    True,
                )
                error_response = f"I encountered an error while processing your request: {str(e)}\n\nPlease ensure the Jaguar n8n workflow is running and accessible."
                body["messages"].append({"role": "assistant", "content": error_response})
                return body
        else:
            await self.emit_status(
                __event_emitter__,
                "error",
                "❌ No messages found in the request body",
                True,
            )
            body["messages"].append(
                {
                    "role": "assistant",
                    "content": "No messages found in the request body",
                }
            )

        return body

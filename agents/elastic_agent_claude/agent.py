from google.adk.models.lite_llm import LiteLlm
from google.adk.agents import LlmAgent
from google.adk.tools.mcp_tool.mcp_toolset import MCPToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams

root_agent = LlmAgent(
    name="elastic_agent_claude",
    model=LiteLlm(model="anthropic/claude-sonnet-4-20250514", max_tokens=4096),
    description=(
        "Agent to answer questions about documents in Elasticsearch."
    ),
    instruction=(
        "You are a helpful agent who can use Elasticsearch tools to answer questions."
    ),
    tools=[
        MCPToolset(
            connection_params=StreamableHTTPConnectionParams(
                url="http://localhost:8080/mcp"
            )
        )
    ]
)
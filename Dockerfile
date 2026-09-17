# Glama builds and inspects MCP servers from a container that speaks stdio.
# Heathy is a hosted, remote-only server, so this image holds no server code:
# it runs mcp-remote as a stdio <-> Streamable HTTP bridge to the live endpoint.
# No credentials are needed; the endpoint is public and read-only.
FROM node:22-alpine

RUN npm install -g mcp-remote@0.14.2

ENTRYPOINT ["mcp-remote", "https://mcp.heathy.org/mcp", "--transport", "http-only"]

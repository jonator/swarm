# Swarm: AI-Powered Development Automation

Swarm is an intelligent development automation platform that transforms how teams handle code implementation and project management.

## Overview

Swarm uses advanced AI agents to automatically:
- Receive and analyze development tasks
- Implement code changes
- Run tests
- Create pull requests
- Integrate with tools like Linear, GitHub, and Slack

## Key Features

- **Multi-Source Integration**: Works seamlessly with Linear, GitHub, and Slack
- **Intelligent Code Generation**: Uses advanced AI models to understand context
- **Collaborative Agent System**: Multiple specialized AI agents work together
- **Continuous Learning**: Adapts to your team's coding style and preferences
- **Scalable Architecture**: Built with Elixir/Phoenix for high concurrency

## Getting Started

### Prerequisites
- Elixir
- Phoenix Framework
- Docker (optional)

### Installation
1. Clone the repository
2. Run `mix setup`
3. Configure environment variables
4. Start the server with `mix phx.server`

### Configuration
Set up the following environment variables:
- `GITHUB_CLIENT_ID`
- `LINEAR_CLIENT_ID`
- `ANTHROPIC_API_KEY`
- `SLACK_BOT_TOKEN`

## Usage

### Linear Integration
Mention `@swarm` in a Linear issue to trigger automated implementation.

### GitHub Integration
Create an issue and tag with `@swarm` for automatic code changes.

### Slack Integration
Use `@swarm` in Slack threads to request code modifications.

## Development

- Run tests: `mix test`
- Code quality: `mix credo`
- Format code: `mix format`

## Contributing

We welcome contributions! Please read our contributing guidelines before submitting pull requests.

## License

See the LICENSE file for details.

## Learn More

- [Phoenix Framework Docs](https://hexdocs.pm/phoenix)
- [Swarm Project Website](https://swarm.dev)

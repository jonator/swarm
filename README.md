# Swarm

AI-powered development automation platform that transforms how teams handle code implementation and project management. Swarm automatically receives development tasks from Linear, GitHub, and Slack, then uses intelligent agents to implement code changes and create pull requests.

## What is Swarm?

Swarm bridges the gap between project management and code implementation. When you mention `@swarm` in Linear issues, GitHub issues, or Slack threads, the system automatically:

1. **Receives and analyzes** the task or request
2. **Clones your repository** and creates a feature branch
3. **Implements the requested changes** using AI-powered coding agents
4. **Runs tests and ensures code quality**
5. **Creates a pull request** with the implemented changes
6. **Integrates with your workflow** by updating Linear issues and notifying stakeholders

## Key Features

- **Multi-Source Integration**: Works with Linear, GitHub, and Slack
- **Intelligent Code Generation**: Uses Claude Sonnet for context-aware implementation
- **Repository Management**: Handles git operations, branching, and pull requests
- **Team Collaboration**: Maintains context across platforms and team members
- **Scalable Architecture**: Built with Elixir/Phoenix for high concurrency
- **Agent Collaboration**: Multiple specialized agents work together on complex tasks

## Agent Types

- **Coder Agent**: Implements code changes, bug fixes, and new features
- **Researcher Agent**: Analyzes codebases, generates documentation, and provides insights

## Getting Started

To start your Phoenix server:

```bash
mix setup                    # Install and setup dependencies
mix phx.server              # Start Phoenix endpoint
```

Visit [`localhost:4000`](http://localhost:4000) from your browser.

## Configuration

### Environment Variables

Required environment variables:
```bash
# GitHub Integration
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret

# Linear Integration
LINEAR_CLIENT_ID=your_linear_client_id
LINEAR_CLIENT_SECRET=your_linear_client_secret

# AI Models
ANTHROPIC_API_KEY=your_anthropic_api_key

# Slack Integration
SLACK_BOT_TOKEN=your_slack_bot_token
```

## Architecture

- **Phoenix Web Framework**: Handles HTTP requests and webhooks
- **Oban Job Processing**: Manages background agent execution
- **FLAME**: Provides isolated execution environments for code operations
- **Ecto/PostgreSQL**: Manages data persistence and agent state
- **LangChain**: Orchestrates AI model interactions
- **Git Integration**: Handles repository operations and version control

## Usage Examples

### Linear Integration
```
# In Linear issue comment:
@swarm implement user authentication with OAuth
```

### GitHub Integration
```
# In GitHub issue:
@swarm optimize database queries for better performance
```

### Slack Integration
```
# In Slack thread:
@swarm help debug the payment processing issue
```

## Development

### Testing
```bash
mix test                    # Run all tests
mix test test/swarm/       # Run swarm-specific tests
```

### Code Quality
- ExUnit for testing
- Credo for code analysis
- Formatter for consistent code style
- Dialyzer for type checking

## Postgres Container

Create and start the postgres container:

```bash
docker run -d \
  --name postgres \
  -p 5432:5432 \
  -v "$PWD/postgres-config.conf":/etc/postgresql/postgresql.conf \
  -v app_postgres_data:/var/lib/postgresql/data \
  -e POSTGRES_PASSWORD=postgres \
  postgres:16-alpine \
  -c 'config_file=/etc/postgresql/postgresql.conf'
```

## Contributing

Swarm welcomes contributions! Whether you're adding new agent types, improving coordination, or enhancing integrations, we encourage community involvement.

When contributing:
- Test agent interactions thoroughly
- Document new behaviors and patterns
- Ensure backward compatibility
- Include comprehensive tests
- Consider performance implications

## Learn More

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
- [Elixir Forum](https://elixirforum.com/c/phoenix-forum)
- [Dependency Visualization](https://depviz.jasonaxelson.com/)

## License

This project is licensed under the terms specified in the repository.
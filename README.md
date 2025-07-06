# Swarm

Swarm is an AI-powered development automation platform that transforms how teams handle code implementation and project management. By integrating with Linear, GitHub, and Slack, Swarm automatically receives development tasks and uses intelligent agents to implement code changes, run tests, and create pull requests.

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
- **Intelligent Code Generation**: Uses advanced AI models (Claude Sonnet) for context-aware implementation
- **Repository Management**: Handles git operations, branching, and pull request creation
- **Team Collaboration**: Maintains context across platforms and team members
- **Scalable Architecture**: Built with Elixir/Phoenix for high concurrency and reliability
- **Agent Collaboration**: Multiple specialized agents work together on complex tasks

## Agent Types

- **Coder Agent**: Implements code changes, bug fixes, and new features
- **Researcher Agent**: Analyzes codebases, generates documentation, and provides insights

## Getting Started

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

### Configuration

Swarm requires configuration for various integrations:

1. **GitHub Integration**: Set up GitHub App credentials for repository access
2. **Linear Integration**: Configure Linear API access for issue management
3. **Slack Integration**: Set up Slack Bot for team communication
4. **AI Models**: Configure Claude Sonnet API credentials for code generation

### Environment Variables

Key environment variables needed:
- `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET`
- `LINEAR_CLIENT_ID` and `LINEAR_CLIENT_SECRET`
- `ANTHROPIC_API_KEY` for Claude integration
- `SLACK_BOT_TOKEN` for Slack integration

## Architecture

Swarm is built on a robust, scalable architecture:

- **Phoenix Web Framework**: Handles HTTP requests and webhooks
- **Oban Job Processing**: Manages background agent execution
- **FLAME**: Provides isolated execution environments for code operations
- **Ecto/PostgreSQL**: Manages data persistence and agent state
- **LangChain**: Orchestrates AI model interactions
- **Git Integration**: Handles repository operations and version control

## Usage Examples

### Linear Integration
Simply mention `@swarm` in any Linear issue comment or assign an issue to `@swarm`, and the system will automatically implement the requested changes.

### GitHub Integration
Create GitHub issues and mention `@swarm` in the description or comments to trigger automated code implementation.

### Slack Integration
Use `@swarm` in Slack threads to request code changes, bug fixes, or analysis with real-time updates.

## Development

### Testing
Run the test suite with:
```bash
mix test
```

### Code Quality
The project uses various tools for code quality:
- ExUnit for testing
- Credo for code analysis
- Formatter for consistent code style
- Dialyzer for type checking

## Postgres Container

1. Create a new volume `app_postgres_data` in OrbStack (MacOS).
2. Use this command to start the postgres container:

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

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix

## Contributing

Swarm welcomes contributions. Whether you're adding new agent types, improving integrations, or developing new AI capabilities, we encourage community involvement.

## License

This project is licensed under the terms specified in the repository.
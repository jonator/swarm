# Swarm

Swarm is an AI-powered development automation platform that integrates with Linear, GitHub, and Slack to automatically implement code changes and manage development tasks.

## What is Swarm?

Swarm bridges project management and code implementation. When you mention `@swarm` in Linear issues, GitHub issues, or Slack threads, the system automatically:

1. **Receives and analyzes** the task or request
2. **Clones your repository** and creates a feature branch
3. **Implements the requested changes** using AI-powered agents
4. **Runs tests and ensures code quality**
5. **Creates a pull request** with the implemented changes
6. **Updates Linear issues** and notifies relevant stakeholders

## Key Features

- **Multi-Source Integration**: Works with Linear, GitHub, and Slack
- **Intelligent Code Generation**: Uses Claude Sonnet for context-aware implementation
- **Repository Management**: Handles git operations, branching, and pull requests
- **Team Collaboration**: Maintains context across platforms and team members
- **Scalable Architecture**: Built with Elixir/Phoenix for reliability

## Getting Started

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

### Environment Variables

Key environment variables needed:
- `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET`
- `LINEAR_CLIENT_ID` and `LINEAR_CLIENT_SECRET`
- `ANTHROPIC_API_KEY` for Claude integration
- `SLACK_BOT_TOKEN` for Slack integration

## Usage Examples

### Linear Integration
Mention `@swarm` in any Linear issue comment or assign an issue to `@swarm` to trigger automated implementation.

### GitHub Integration
Create GitHub issues and mention `@swarm` in the description or comments to trigger automated code implementation.

### Slack Integration
Use `@swarm` in Slack threads to request code changes, bug fixes, or analysis.

## Architecture

Swarm is built on:
- **Phoenix Web Framework**: Handles HTTP requests and webhooks
- **Oban Job Processing**: Manages background task execution
- **FLAME**: Provides isolated execution environments
- **Ecto/PostgreSQL**: Manages data persistence
- **LangChain**: Orchestrates AI model interactions

## Development

### Testing
Run the test suite with:
```bash
mix test
```

### Code Quality
The project uses:
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

## Tools

* **Dependency Analysis**: https://depviz.jasonaxelson.com/
* **Tidewave**: Included in deps. Follow [these instructions](https://hexdocs.pm/tidewave/installation.html) to activate.

## Contributing

Swarm welcomes contributions. Whether you're adding new features, improving integrations, or enhancing AI capabilities, we encourage community involvement.

## License

This project is licensed under the terms specified in the repository.
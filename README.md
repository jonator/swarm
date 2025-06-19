# Swarm

Swarm is an AI-powered development automation platform that transforms how teams handle code implementation and project management. By integrating with popular tools like Linear, GitHub, and Slack, Swarm automatically receives development tasks and uses intelligent agents to implement code changes, run tests, and create pull requests.

## What is Swarm?

Swarm is a sophisticated system that bridges the gap between project management and code implementation. When you mention `@swarm` in Linear issues, GitHub issues, or Slack threads, the system automatically:

1. **Receives and analyzes** the task or request
2. **Clones your repository** and creates a feature branch
3. **Implements the requested changes** using AI-powered coding agents
4. **Runs tests and ensures code quality**
5. **Creates a pull request** with the implemented changes
6. **Integrates with your workflow** by updating Linear issues and notifying relevant stakeholders

### Key Features

- **Multi-Source Integration**: Seamlessly works with Linear, GitHub, and Slack
- **Intelligent Code Generation**: Uses advanced AI models (Claude Sonnet) to understand context and implement changes
- **Repository Management**: Automatically handles git operations, branching, and pull request creation
- **Team Collaboration**: Maintains context across different platforms and team members
- **Scalable Architecture**: Built with Elixir/Phoenix for high concurrency and reliability
- **Flexible Agent System**: Different types of agents (Coder, Researcher) handle various types of tasks

### How It Works

1. **Task Detection**: Swarm monitors your Linear issues, GitHub repositories, and Slack channels for `@swarm` mentions
2. **Context Analysis**: The system analyzes the request, gathers relevant context, and determines the appropriate action
3. **Agent Dispatch**: Specialized agents (like the Coder agent) are dispatched to handle specific types of work
4. **Code Implementation**: Agents clone repositories, analyze existing code, implement changes, and run tests
5. **Pull Request Creation**: Completed work is packaged into pull requests with detailed descriptions
6. **Integration Updates**: Linear issues are updated, and relevant stakeholders are notified

### Agent Types

- **Coder Agent**: Implements code changes, bug fixes, and new features
- **Researcher Agent**: Analyzes codebases, generates documentation, and provides insights
- **Planner Agent**: Breaks down complex tasks into manageable subtasks

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
- **Ecto/PostgreSQL**: Manages data persistence
- **LangChain**: Orchestrates AI model interactions
- **Git Integration**: Handles repository operations and version control

## Usage Examples

### Linear Integration
Simply mention `@swarm` in any Linear issue comment or assign an issue to `@swarm`, and the system will automatically implement the requested changes.

### GitHub Integration
Create GitHub issues and mention `@swarm` in the description or comments to trigger automated code implementation.

### Slack Integration
Use `@swarm` in Slack threads to request code changes, bug fixes, or analysis.

## Development

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

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

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

## Analyze

Use this tool to view dependency graph of a project.
https://depviz.jasonaxelson.com/

## Tidewave

Included in deps for this project. To activate, follow [these instructions](https://hexdocs.pm/tidewave/installation.html)

## Contributing

Swarm is designed to be extensible and welcomes contributions. Whether you're adding new agent types, improving integrations, or enhancing the AI capabilities, we encourage community involvement.

## License

This project is licensed under the terms specified in the repository.
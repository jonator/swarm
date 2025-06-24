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

## The Swarm Intelligence System

### Core Swarm Concepts

**Swarm** operates on the principle of distributed intelligence, where multiple specialized AI agents work together to accomplish complex development tasks. Each agent in the swarm has specific capabilities and can collaborate with other agents to solve problems that would be difficult for a single agent to handle alone.

### Swarm Agent Orchestration

The swarm system uses sophisticated orchestration to manage agent interactions:

- **Task Distribution**: Complex tasks are automatically broken down and distributed among appropriate agents
- **Context Sharing**: Agents share context and findings to maintain consistency across the swarm
- **Collaborative Problem Solving**: Multiple agents can work on different aspects of the same problem simultaneously
- **Quality Assurance**: Agents can review and validate each other's work before implementation

### Swarm Learning and Adaptation

The swarm continuously learns and adapts:

- **Pattern Recognition**: Agents learn from successful implementations and common patterns in your codebase
- **Team Preferences**: The swarm adapts to your team's coding style, conventions, and preferences
- **Domain Expertise**: Over time, agents develop specialized knowledge about your specific domain and technologies
- **Feedback Integration**: The swarm incorporates feedback from code reviews and testing results

### Key Features

- **Multi-Source Integration**: Seamlessly works with Linear, GitHub, and Slack
- **Intelligent Code Generation**: Uses advanced AI models (Claude Sonnet) to understand context and implement changes
- **Repository Management**: Automatically handles git operations, branching, and pull request creation
- **Team Collaboration**: Maintains context across different platforms and team members
- **Scalable Architecture**: Built with Elixir/Phoenix for high concurrency and reliability
- **Flexible Agent System**: Different types of agents (Coder, Researcher) handle various types of tasks
- **Swarm Intelligence**: Agents collaborate and share knowledge to solve complex problems
- **Continuous Learning**: The swarm improves over time by learning from your codebase and team practices

### How It Works

1. **Task Detection**: Swarm monitors your Linear issues, GitHub repositories, and Slack channels for `@swarm` mentions
2. **Context Analysis**: The system analyzes the request, gathers relevant context, and determines the appropriate action
3. **Agent Dispatch**: Specialized agents (like the Coder agent) are dispatched to handle specific types of work
4. **Swarm Coordination**: Multiple agents may collaborate on complex tasks, sharing context and findings
5. **Code Implementation**: Agents clone repositories, analyze existing code, implement changes, and run tests
6. **Quality Validation**: Other agents in the swarm review and validate the implementation
7. **Pull Request Creation**: Completed work is packaged into pull requests with detailed descriptions
8. **Integration Updates**: Linear issues are updated, and relevant stakeholders are notified

### Agent Types in the Swarm

- **Coder Agent**: Implements code changes, bug fixes, and new features with deep understanding of your codebase
- **Researcher Agent**: Analyzes codebases, generates documentation, and provides insights about architecture and patterns
- **Planner Agent**: Breaks down complex tasks into manageable subtasks and coordinates multi-agent workflows
- **Reviewer Agent**: Performs code quality checks and ensures implementations meet standards
- **Tester Agent**: Generates and runs tests to validate implementations

### Swarm Communication Patterns

The swarm uses sophisticated communication patterns to ensure effective collaboration:

- **Broadcast Messages**: Important findings are shared across all relevant agents
- **Direct Agent Communication**: Agents can directly communicate for specific collaborations
- **Context Propagation**: Shared context ensures all agents have the necessary information
- **Consensus Building**: Agents can reach consensus on implementation approaches

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
5. **Swarm Settings**: Configure agent collaboration parameters and swarm behavior

### Environment Variables

Key environment variables needed:
- `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET`
- `LINEAR_CLIENT_ID` and `LINEAR_CLIENT_SECRET`
- `ANTHROPIC_API_KEY` for Claude integration
- `SLACK_BOT_TOKEN` for Slack integration
- `SWARM_MAX_AGENTS` to control swarm size
- `SWARM_COLLABORATION_MODE` to set collaboration patterns

## Architecture

Swarm is built on a robust, scalable architecture designed to support intelligent agent collaboration:

- **Phoenix Web Framework**: Handles HTTP requests and webhooks
- **Oban Job Processing**: Manages background agent execution and swarm coordination
- **FLAME**: Provides isolated execution environments for code operations
- **Ecto/PostgreSQL**: Manages data persistence and agent state
- **LangChain**: Orchestrates AI model interactions and agent communication
- **Git Integration**: Handles repository operations and version control
- **Swarm Coordination Layer**: Manages agent collaboration and task distribution

### Swarm Scalability

The swarm architecture is designed for scalability:

- **Horizontal Scaling**: Add more agents to handle increased workload
- **Load Balancing**: Tasks are automatically distributed across available agents
- **Resource Management**: Intelligent resource allocation prevents conflicts
- **Fault Tolerance**: The swarm can continue operating even if individual agents fail

## Usage Examples

### Linear Integration
Simply mention `@swarm` in any Linear issue comment or assign an issue to `@swarm`, and the system will automatically implement the requested changes. The swarm will analyze the issue, coordinate appropriate agents, and deliver a comprehensive solution.

### GitHub Integration
Create GitHub issues and mention `@swarm` in the description or comments to trigger automated code implementation. The swarm can handle everything from simple bug fixes to complex feature implementations.

### Slack Integration
Use `@swarm` in Slack threads to request code changes, bug fixes, or analysis. The swarm will provide real-time updates on progress and coordinate with your team through Slack.

### Advanced Swarm Usage

- **Complex Refactoring**: The swarm can coordinate multiple agents to handle large-scale refactoring projects
- **Architecture Analysis**: Research agents can analyze your codebase and provide architectural recommendations
- **Performance Optimization**: Specialized agents can identify and implement performance improvements
- **Documentation Generation**: The swarm can generate comprehensive documentation for your codebase

## Development

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

### Testing
Run the test suite with:
```bash
mix test
```

### Swarm Development
When developing swarm functionality:
```bash
# Run swarm-specific tests
mix test test/swarm/

# Test agent coordination
mix test test/swarm/agents_test.exs

# Test swarm workers
mix test test/swarm/workers_test.exs
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

<<<<<<< HEAD
## Contributing

Swarm is designed to be extensible and welcomes contributions. Whether you're adding new agent types, improving swarm coordination, enhancing integrations, or developing new AI capabilities, we encourage community involvement.

### Contributing to Swarm Intelligence

When contributing to the swarm system:
- Consider how new features will affect agent collaboration
- Test agent interactions thoroughly
- Document new swarm behaviors and patterns
- Ensure backward compatibility with existing agent types

## License

This project is licensed under the terms specified in the repository.
=======
## Postgres Container

1. Create a new volume `app_postgres_data` in OrbStack (MacOS).
2. Use this command to start the postgres container using the conf file locally:

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
>>>>>>> sync-agent

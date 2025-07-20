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

The swarm architecture is inspired by natural swarm intelligence found in bee colonies, ant colonies, and bird flocks, where simple individual agents following basic rules create complex, intelligent collective behavior. In our system, AI agents communicate, coordinate, and collaborate to solve software development challenges that exceed the capabilities of any single agent.

### Swarm Agent Orchestration

The swarm system uses sophisticated orchestration to manage agent interactions:

- **Task Distribution**: Complex tasks are automatically broken down and distributed among appropriate agents based on their specializations and current workload
- **Context Sharing**: Agents share context and findings through a centralized knowledge base, maintaining consistency across the swarm
- **Collaborative Problem Solving**: Multiple agents can work on different aspects of the same problem simultaneously, with real-time coordination
- **Quality Assurance**: Agents can review and validate each other's work before implementation, ensuring high-quality output
- **Dynamic Load Balancing**: The swarm automatically redistributes work based on agent availability and expertise
- **Conflict Resolution**: Built-in mechanisms handle conflicts when agents have different approaches to the same problem

### Swarm Learning and Adaptation

The swarm continuously learns and adapts through multiple mechanisms:

- **Pattern Recognition**: Agents learn from successful implementations and common patterns in your codebase, building a knowledge base of best practices
- **Team Preferences**: The swarm adapts to your team's coding style, conventions, and preferences through observation and feedback
- **Domain Expertise**: Over time, agents develop specialized knowledge about your specific domain, technologies, and business logic
- **Feedback Integration**: The swarm incorporates feedback from code reviews, testing results, and deployment outcomes
- **Cross-Project Learning**: Knowledge gained from one project can be applied to similar challenges in other projects
- **Evolutionary Improvement**: The swarm's problem-solving strategies evolve based on success rates and efficiency metrics

### Swarm Communication Protocols

Swarm agents use sophisticated communication protocols to ensure effective collaboration:

- **Broadcast Messages**: Important findings, warnings, or discoveries are shared across all relevant agents in the swarm
- **Direct Agent Communication**: Agents can establish direct communication channels for specific collaborations or complex negotiations
- **Context Propagation**: Shared context ensures all agents have access to necessary information without overwhelming individual agents
- **Consensus Building**: Agents can reach consensus on implementation approaches through structured decision-making processes
- **Hierarchical Communication**: Some agents act as coordinators, managing communication flow and preventing information overload
- **Asynchronous Messaging**: Agents can work independently while staying synchronized through asynchronous message passing

### Key Features

- **Multi-Source Integration**: Seamlessly works with Linear, GitHub, and Slack
- **Intelligent Code Generation**: Uses advanced AI models (Claude Sonnet) to understand context and implement changes
- **Repository Management**: Automatically handles git operations, branching, and pull request creation
- **Team Collaboration**: Maintains context across different platforms and team members
- **Scalable Architecture**: Built with Elixir/Phoenix for high concurrency and reliability
- **Flexible Agent System**: Different types of agents (Coder, Researcher) handle various types of tasks
- **Swarm Intelligence**: Agents collaborate and share knowledge to solve complex problems
- **Continuous Learning**: The swarm improves over time by learning from your codebase and team practices
- **Fault Tolerance**: The swarm continues operating even when individual agents encounter errors
- **Resource Optimization**: Intelligent resource allocation prevents conflicts and maximizes efficiency

### How It Works

1. **Task Detection**: Swarm monitors your Linear issues, GitHub repositories, and Slack channels for `@swarm` mentions
2. **Context Analysis**: The system analyzes the request, gathers relevant context, and determines the appropriate action
3. **Swarm Assembly**: The system assembles an appropriate swarm of agents based on the task complexity and requirements
4. **Agent Dispatch**: Specialized agents (like the Coder agent) are dispatched to handle specific types of work
5. **Swarm Coordination**: Multiple agents collaborate on complex tasks, sharing context and findings in real-time
6. **Code Implementation**: Agents clone repositories, analyze existing code, implement changes, and run tests
7. **Quality Validation**: Other agents in the swarm review and validate the implementation through peer review
8. **Pull Request Creation**: Completed work is packaged into pull requests with detailed descriptions and documentation
9. **Integration Updates**: Linear issues are updated, and relevant stakeholders are notified through configured channels
10. **Swarm Dissolution**: Once the task is complete, the swarm dissolves, but knowledge is retained for future tasks

### Agent Types in the Swarm

- **Coder Agent**: Implements code changes, bug fixes, and new features with deep understanding of your codebase and architectural patterns
- **Researcher Agent**: Analyzes codebases, generates documentation, provides insights about architecture, and investigates complex technical questions
- **Planner Agent**: Breaks down complex tasks into manageable subtasks, coordinates multi-agent workflows, and manages project timelines
- **Reviewer Agent**: Performs comprehensive code quality checks, ensures implementations meet standards, and provides constructive feedback
- **Tester Agent**: Generates and runs tests to validate implementations, performs regression testing, and ensures code coverage
- **Security Agent**: Analyzes code for security vulnerabilities, implements security best practices, and ensures compliance
- **Performance Agent**: Identifies performance bottlenecks, optimizes code efficiency, and monitors system performance
- **Documentation Agent**: Creates and maintains documentation, generates API docs, and ensures knowledge transfer
- **Integration Agent**: Manages external service integrations, handles API connections, and ensures system interoperability

### Swarm Behavioral Patterns

The swarm exhibits several intelligent behavioral patterns:

- **Emergent Problem Solving**: Complex solutions emerge from simple agent interactions
- **Adaptive Task Allocation**: Work distribution adapts based on agent expertise and availability
- **Collective Intelligence**: The swarm's collective knowledge exceeds the sum of individual agent capabilities
- **Self-Organization**: Agents organize themselves into effective working groups without central control
- **Resilient Operation**: The swarm maintains functionality even when individual agents fail or become unavailable
- **Continuous Optimization**: The swarm continuously optimizes its processes and workflows for better efficiency

### Swarm Scalability and Performance

The swarm architecture is designed for enterprise-scale operations:

- **Horizontal Scaling**: Add more agents to handle increased workload without architectural changes
- **Load Balancing**: Tasks are automatically distributed across available agents based on capacity and expertise
- **Resource Management**: Intelligent resource allocation prevents conflicts and ensures optimal utilization
- **Fault Tolerance**: The swarm can continue operating even if individual agents fail or become unavailable
- **Performance Monitoring**: Real-time monitoring of swarm performance with automatic optimization
- **Cost Optimization**: Efficient resource usage minimizes operational costs while maximizing output quality

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
- `SWARM_MAX_AGENTS` to control swarm size (default: 10)
- `SWARM_COLLABORATION_MODE` to set collaboration patterns (cooperative, competitive, or hybrid)
- `SWARM_LEARNING_RATE` to control how quickly the swarm adapts (0.1-1.0)
- `SWARM_CONSENSUS_THRESHOLD` to set agreement level needed for decisions (0.5-1.0)

## Architecture

Swarm is built on a robust, scalable architecture designed to support intelligent agent collaboration:

- **Phoenix Web Framework**: Handles HTTP requests and webhooks
- **Oban Job Processing**: Manages background agent execution and swarm coordination
- **FLAME**: Provides isolated execution environments for code operations
- **Ecto/PostgreSQL**: Manages data persistence and agent state
- **LangChain**: Orchestrates AI model interactions and agent communication
- **Git Integration**: Handles repository operations and version control
- **Swarm Coordination Layer**: Manages agent collaboration and task distribution
- **Message Passing System**: Enables real-time agent communication
- **Knowledge Base**: Centralized storage for swarm learning and context sharing

### Network Security for Agents

Swarm agents run in isolated Docker containers with network restrictions to prevent access to internal infrastructure:

#### Security Measures
- **External-Only Access**: Agents can only access external internet, not internal Fly.io networks
- **Blocked Networks**: 
  - RFC 1918 private networks (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)
  - Link-local addresses (169.254.0.0/16) including Fly.io metadata service
- **Allowed Access**: Public internet APIs (GitHub, Linear, Anthropic, etc.)

#### Implementation
Network restrictions are applied at container startup via iptables rules in `/usr/local/bin/apply-network-security.sh`. These rules ensure agents cannot access:
- Internal Fly.io services
- Other applications in the same organization  
- Private network infrastructure
- Fly.io metadata endpoints

This provides defense-in-depth security while maintaining necessary external API access for agent functionality.

### Swarm Architecture Components

The swarm system consists of several key architectural components:

- **Swarm Orchestrator**: Central coordinator that manages agent lifecycle and task distribution
- **Agent Registry**: Maintains information about available agents, their capabilities, and current status
- **Communication Hub**: Facilitates message passing and coordination between agents
- **Knowledge Repository**: Stores shared knowledge, patterns, and learning outcomes
- **Task Queue**: Manages incoming requests and distributes them to appropriate agent swarms
- **Monitoring System**: Tracks swarm performance, agent health, and system metrics

## Usage Examples

### Linear Integration
Simply mention `@swarm` in any Linear issue comment or assign an issue to `@swarm`, and the system will automatically implement the requested changes. The swarm will analyze the issue, coordinate appropriate agents, and deliver a comprehensive solution.

**Example Linear Issue Workflow:**
1. Create a Linear issue: "Implement user authentication with OAuth"
2. Mention `@swarm` in the issue description or comments
3. The swarm assembles: Planner Agent analyzes requirements, Security Agent reviews auth patterns, Coder Agent implements the feature
4. Multiple agents collaborate to ensure secure, well-tested implementation
5. Pull request is created with comprehensive documentation and tests

### GitHub Integration
Create GitHub issues and mention `@swarm` in the description or comments to trigger automated code implementation. The swarm can handle everything from simple bug fixes to complex feature implementations.

**Example GitHub Workflow:**
1. Open GitHub issue: "Performance optimization for database queries"
2. Tag with `@swarm` to trigger swarm activation
3. Performance Agent analyzes current query patterns, Researcher Agent investigates optimization strategies
4. Coder Agent implements optimizations while Tester Agent ensures no regressions
5. Comprehensive pull request includes performance benchmarks and documentation

### Slack Integration
Use `@swarm` in Slack threads to request code changes, bug fixes, or analysis. The swarm will provide real-time updates on progress and coordinate with your team through Slack.

**Example Slack Workflow:**
1. Post in Slack: "@swarm can you help debug the payment processing issue?"
2. Swarm responds immediately with initial analysis
3. Multiple agents investigate: Researcher Agent analyzes logs, Coder Agent identifies the issue
4. Real-time updates in Slack thread as agents collaborate
5. Solution implemented and tested with full transparency in Slack

### Advanced Swarm Usage

- **Complex Refactoring**: The swarm can coordinate multiple agents to handle large-scale refactoring projects, with Planner Agents managing the overall strategy and multiple Coder Agents working on different modules simultaneously
- **Architecture Analysis**: Research agents can analyze your codebase and provide architectural recommendations, identifying patterns, anti-patterns, and optimization opportunities
- **Performance Optimization**: Specialized Performance Agents can identify bottlenecks, implement optimizations, and validate improvements through comprehensive testing
- **Documentation Generation**: The swarm can generate comprehensive documentation for your codebase, including API documentation, architectural diagrams, and user guides
- **Security Audits**: Security Agents can perform comprehensive security audits, identifying vulnerabilities and implementing fixes
- **Migration Projects**: The swarm can coordinate complex migration projects, handling database migrations, framework upgrades, and technology transitions

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

# Test swarm communication
mix test test/swarm/communication_test.exs

# Test swarm learning
mix test test/swarm/learning_test.exs
```

### Code Quality
The project uses various tools for code quality:
- ExUnit for testing
- Credo for code analysis
- Formatter for consistent code style
- Dialyzer for type checking

### Swarm Development Guidelines

When contributing to swarm functionality:
- **Agent Design**: Follow the single responsibility principle for agent design
- **Communication Patterns**: Use established communication protocols for agent interaction
- **Error Handling**: Implement robust error handling and recovery mechanisms
- **Testing**: Include comprehensive tests for agent behavior and swarm coordination
- **Documentation**: Document agent capabilities and interaction patterns
- **Performance**: Consider performance implications of agent communication and coordination

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

Swarm is designed to be extensible and welcomes contributions. Whether you're adding new agent types, improving swarm coordination, enhancing integrations, or developing new AI capabilities, we encourage community involvement.

### Contributing to Swarm Intelligence

When contributing to the swarm system:
- Consider how new features will affect agent collaboration and swarm dynamics
- Test agent interactions thoroughly, including edge cases and failure scenarios
- Document new swarm behaviors, patterns, and communication protocols
- Ensure backward compatibility with existing agent types and swarm configurations
- Follow established patterns for agent design and implementation
- Include comprehensive tests for swarm coordination and agent behavior
- Consider performance and scalability implications of new features

### Swarm Extension Points

The swarm system provides several extension points for customization:
- **Custom Agent Types**: Implement specialized agents for domain-specific tasks
- **Communication Protocols**: Extend agent communication with custom message types
- **Learning Algorithms**: Implement custom learning and adaptation strategies
- **Integration Connectors**: Add support for additional platforms and tools
- **Orchestration Strategies**: Customize how agents are assembled and coordinated

## License

This project is licensed under the terms specified in the repository.

## Docker FLAME Backend

If using orbstack, ensure you use it's context before building images:
```bash
docker context use orbstack
```

Expose Docker Engine API in local loop:
```bash
socat TCP-LISTEN:2375,reuseaddr,fork UNIX-CONNECT:/var/run/docker.sock &
```

Build the docker image:
```bash
docker build -f ./Dockerfile.dev --target dev -t swarmdev:latest .
```

Run for debugging:
```bash
docker run -it --rm --name swarmdev \
  --publish 127.0.0.1:4369:4369 \
  --publish 9000-9010:9000-9010 \
  --publish 4000:4000 \
  --env NODE_SNAME=swarmdev \
  --env SECRET_KEY_BASE=test \
  --env RELEASE_COOKIE=test \
  --env RELEASE_NODE=swarmdev \
  --network host \
  swarmdev:latest
```

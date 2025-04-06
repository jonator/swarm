defmodule Swarm.Instructor.BranchName do
  use Ecto.Schema
  use Instructor

  @llm_doc """
  ## Fields
  - `branch_name`: A string representing a git branch name derived from the instructions.
  """
  @primary_key false
  embedded_schema do
    field(:branch_name, :string)
  end

  def generate_branch_name(instructions) do
    Instructor.chat_completion(
      [
        model: "gpt-4o-mini",
        response_model: __MODULE__,
        messages: [
          %{
            role: "user",
            content: """
            You are a helpful assistant that generates appropriate git branch names based on instructions.

            Create a concise, kebab-case branch name that summarizes the following instructions:
            #{instructions}

            Conventional Branch 1.0.0
            Summary
            Conventional Branch refers to a structured and standardized naming convention for Git branches which aims to make branch more readable and actionable. We've suggested some branch prefixes you might want to use but you can also specify your own naming convention. A consistent naming convention makes it easier to identify branches by type.

            Key Points
            Purpose-driven Branch Names: Each branch name clearly indicates its purpose, making it easy for all developers to understand what the branch is for.
            Integration with CI/CD: By using consistent branch names, it can help automated systems (like Continuous Integration/Continuous Deployment pipelines) to trigger specific actions based on the branch type (e.g., auto-deployment from release branches).
            Team Collaboration : It encourages collaboration within teams by making branch purpose explicit, reducing misunderstandings and making it easier for team members to switch between tasks without confusion.
            Specification
            Branch Naming Prefixes
            The branch specification by describing with feature/, bugfix/, hotfix/, release/ and chore/ and it should be structured as follows:

            main: The main development branch (e.g., main, master, or develop)
            - feature/: For new features (e.g., feature/add-login-page)
            - bugfix/: For bug fixes (e.g., bugfix/fix-header-bug)
            - hotfix/: For urgent fixes (e.g., hotfix/security-patch)
            - release/: For branches preparing a release (e.g., release/v1.2.0)
            - chore/: For non-code tasks like dependency, docs updates (e.g., chore/update-dependencies)
            Basic Rules
            Use Lowercase Alphanumeric and Hyphens: Always use lowercase letters (a-z), numbers (0-9), and hyphens to separate words. Avoid special characters, underscores, or spaces.
            No Consecutive or Trailing Hyphens: Ensure that hyphens are used singly, with no consecutive hyphens (feature/new--login) or at the end (feature/new-login-).
            Keep It Clear and Concise: The branch name should be descriptive yet concise, clearly indicating the purpose of the work.
            Include Ticket Numbers: If applicable, include the ticket number from your project management tool to make tracking easier. For example, for a ticket issue-123, the branch name could be feature/issue-123-new-login.
            Conclusion
            Clear Communication: The branch name alone provides a clear understanding of its purpose the code change.
            Automation-Friendly: Easily hooks into automation processes (e.g., different workflows for feature, release, etc.).
            Scalability: Works well in large teams where many developers are working on different tasks simultaneously.
            In summary, conventional branch is designed to improve project organization, communication, and automation within Git workflows.
            """
          }
        ]
      ],
      adapter: Instructor.Adapters.OpenAI,
      api_key: Application.fetch_env!(:instructor, :openai)[:api_key]
    )
  end
end

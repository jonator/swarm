# Swarm

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

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

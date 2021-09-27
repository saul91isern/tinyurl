# Tinyurl

## Development:

To deploy and test the backend we need a postgres database and a redis instance. We use two different redis instances for execution (port 6379) and testing purposes (port 6380). You can use your own instances or otherwise, the docker-compose file in the ci folder offers the necessary tools to run the project (Refer to production section).

Connection information:

  * Postgres:
    * Host: `postgres`.
    * Port: 5432.
  * Redis:
    * Host: `redis`.
    * Port: 6379.
  * Redis test:
    * Host: `redis`.
    + Port: 6380.

First we need to launch a redis and a postgres instance.

To start your Phoenix server:

  * Install dependencies with `mix deps.get`.
  + Test application `mix test`.
  * Create and migrate your database with `mix ecto.setup`.
  * Start Phoenix endpoint with `mix phx.server`.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Production:

We need to install docker and docker compose to run the app in production mode.
There is a `ci/` folder simulating the existing stages in a ci pipeline:

To run your Application:

  * Export needed variables: run `source ci/env.sh` in project root. Feel free to change any of the variables within the file 
  to adapt the installation to your needs.
  * Build the application `docker-compose run --rm build` in project root. This will generate the prod app under `_build`.
  * Testing `docker-compose run --rm test` in project root.
  * Service `docker-compose run --rm --service-ports service` in project root.

Now you can visit [`localhost:4001`](http://localhost:4000) from your browser.

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
  * Docker: https://www.docker.com/
  * Docker compose: https://docs.docker.com/compose/
  * Redis: https://redis.io/

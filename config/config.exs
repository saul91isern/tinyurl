# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :tinyurl,
  ecto_repos: [Tinyurl.Repo]

config :tinyurl, :env, Mix.env()

config :tinyurl, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [router: TinyurlWeb.Router]
  }

# Configures the endpoint
config :tinyurl, TinyurlWeb.Endpoint,
  http: [port: 4000],
  url: [host: "localhost"],
  render_errors: [view: TinyurlWeb.ErrorView, accepts: ~w(json), layout: false]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason
config :phoenix_swagger, :json_library, Jason

config :redix,
  redis_host: "redis",
  redis_port: 6379

config :tinyurl, Tinyurl.Scheduler,
  jobs: [
    [
      schedule: "@hourly",
      task: {Tinyurl.Cache.LinkCache, :reset_seed, []},
      run_strategy: Quantum.RunStrategy.Local
    ],
    [
      schedule: "@reboot",
      task: {Tinyurl.Cache.LinkCache, :reset_seed, []},
      run_strategy: Quantum.RunStrategy.Local
    ],
    [
      schedule: "@reboot",
      task: {Tinyurl.Cache.LinkCache, :migrate, []},
      run_strategy: Quantum.RunStrategy.Local
    ],
    [
      schedule: "@daily",
      task: {Tinyurl.Cache.LinkCache, :migrate, []},
      run_strategy: Quantum.RunStrategy.Local
    ]
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

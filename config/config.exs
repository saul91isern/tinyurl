# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :tinyurl,
  ecto_repos: [Tinyurl.Repo]

# Configures the endpoint
config :tinyurl, TinyurlWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "I/Z5281Pc266ZULl69+Qd1FZRsFeMQolIfiPftHnCIyrGyFmrMGyvgDJ+yjnWteS",
  render_errors: [view: TinyurlWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Tinyurl.PubSub,
  live_view: [signing_salt: "BmEJ9YSJ"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :redix,
  redis_host: "redis",
  redis_port: 6379 

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

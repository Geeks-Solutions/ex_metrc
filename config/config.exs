# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :ex_metrc, ExMetrcWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "skQowNHE0UxaMp76lT9aDOSgYeBv4PD1/tYYG+/71Ee0s1EN9qlT4EEeCn9BQf5U",
  render_errors: [view: ExMetrcWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: ExMetrc.PubSub,
  live_view: [signing_salt: "rB/acuSq"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# this is added to test the library separately without integrating it in another project
config :ex_metrc,
  endpoint: "https://sandbox-api-ca.metrc.com/",
  vendor_key: "UaTU7SAzghY2mLsj6H8eza7ufC4u7ckWpXTaCWNXatfwmPzl"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config("#{Mix.env()}.exs")

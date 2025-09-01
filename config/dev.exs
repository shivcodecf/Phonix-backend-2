import Config

config :chat_server, ChatServerWeb.Endpoint,
  # Bind only to localhost (127.0.0.1). Change to {0,0,0,0} if you want access from other devices.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev-secret-key",
  watchers: [],
  server: true  

# Enable dev routes like LiveDashboard
config :chat_server, dev_routes: true

# Logs cleaner in dev
config :logger, :console, format: "[$level] $message\n"

# Better stacktrace in dev (don’t enable in prod!)
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh API client (emails) in dev
config :swoosh, :api_client, false

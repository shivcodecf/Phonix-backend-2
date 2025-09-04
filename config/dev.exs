import Config

config :chat_server, ChatServerWeb.Endpoint,
  # Bind to localhost only in dev
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev-secret-key",   # Only for local dev
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

# ✅ Supabase keys in dev (safe defaults or dummy values)
config :chat_server,
  supabase_url: "https://psvhvupdhtzglueldsze.supabase.co",
  supabase_anon_key: System.get_env("SUPABASE_ANON_KEY") || "dev-anon-key",
  supabase_service_key: System.get_env("SUPABASE_SERVICE_KEY") || "dev-service-key",
  supabase_jwt_secret: System.get_env("SUPABASE_JWT_SECRET") || "dev-jwt-secret",
  edge_function_secret: System.get_env("EDGE_FUNCTION_SECRET") || "dev-edge-secret"

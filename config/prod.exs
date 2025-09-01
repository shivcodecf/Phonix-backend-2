import Config

# Production endpoint
config :chat_server, ChatServerWeb.Endpoint,
  url: [host: System.get_env("PHX_HOST") || "example.com", port: 443],
  http: [
    ip: {0, 0, 0, 0},
    port: String.to_integer(System.get_env("PORT") || "4000")
  ],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  server: true

# Logger for prod
config :logger, level: :info

# Disable dev routes in prod
config :chat_server, dev_routes: false

# ✅ Add Supabase credentials here
config :chat_server,
  supabase_url: System.get_env("SUPABASE_URL"),
  supabase_anon_key: System.get_env("SUPABASE_ANON_KEY"),
  supabase_service_key: System.get_env("SUPABASE_SERVICE_KEY"),
  supabase_jwt_secret: System.get_env("SUPABASE_JWT_SECRET")

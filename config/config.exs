import Config

# Phoenix Endpoint (base setup)
config :chat_server, ChatServerWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: ChatServerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ChatServer.PubSub,
  live_view: [signing_salt: "yoursalt"]

# Supabase integration
config :chat_server,
  supabase_url: "https://psvhvupdhtzglueldsze.supabase.co",
  supabase_anon_key: System.get_env("SUPABASE_ANON_KEY"),
  supabase_service_key: System.get_env("SUPABASE_SERVICE_KEY"),   
  supabase_jwt_secret: System.get_env("SUPABASE_JWT_SECRET"),
  edge_function_secret: "ehdecgegedvegdedgevdegdvegdevdgedhdehd"

# Swoosh — disable email client
config :swoosh, :api_client, false

# Logger
config :logger, :console,
  format: "[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing
config :phoenix, :json_library, Jason

# Import environment specific configs
import_config "#{config_env()}.exs"

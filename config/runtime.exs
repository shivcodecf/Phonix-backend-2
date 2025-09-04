import Config

if System.get_env("PHX_SERVER") do
  config :chat_server, ChatServerWeb.Endpoint, server: true
end

# Supabase + Edge (all envs)
config :chat_server,
  supabase_url: System.get_env("SUPABASE_URL") || raise("SUPABASE_URL missing"),
  supabase_anon_key: System.get_env("SUPABASE_ANON_KEY") || raise("SUPABASE_ANON_KEY missing"),
  supabase_service_key: System.get_env("SUPABASE_SERVICE_KEY") || raise("SUPABASE_SERVICE_KEY missing"),
  supabase_jwt_secret: System.get_env("SUPABASE_JWT_SECRET") || raise("SUPABASE_JWT_SECRET missing"),
  edge_function_secret: System.get_env("EDGE_FUNCTION_SECRET") || raise("EDGE_FUNCTION_SECRET missing")

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :chat_server, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  # ✅ Use Bandit in prod
  config :chat_server, ChatServerWeb.Endpoint,
    adapter: Bandit.PhoenixAdapter,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base,
    server: true
end

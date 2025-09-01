import Config

config :chat_server, ChatServerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-secret-key",
  server: false   # ✅ Don’t run web server in tests

# Reduce log noise during tests
config :logger, level: :warn

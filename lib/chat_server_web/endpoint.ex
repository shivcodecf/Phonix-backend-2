defmodule ChatServerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :chat_server

  @session_options [
    store: :cookie,
    key: "_chat_server_key",
    signing_salt: "UAUXXkdQ",
    same_site: "Lax",
    secure: config_env() == :prod
  ]

  # Compute WS origin opts at compile time
  @ws_origin_opts if Mix.env() == :prod,
                    do: [check_origin: [System.get_env("PHX_HOST")]],
                    else: []

  # Compute CORS origins at compile time (ENV read is fine here)
  @cors_origins case Mix.env() do
                  :prod ->
                    System.get_env("CORS_ORIGINS")
                    |> to_string()
                    |> String.split(~r/\s*,\s*/, trim: true)
                  _ ->
                    ["http://localhost:5173"]
                end

  # Static assets
  plug Plug.Static,
    at: "/",
    from: :chat_server,
    gzip: not Application.compile_env(:chat_server, :code_reloader, false),
    only: ChatServerWeb.static_paths(),
    headers: [{"cache-control", "public, max-age=31536000, immutable"}]

  # Dev-only code reloader + request logger
  if Application.compile_env(:chat_server, :code_reloader, false) do
    plug Phoenix.CodeReloader
    plug Phoenix.LiveDashboard.RequestLogger,
      param_key: "request_logger",
      cookie_key: "request_logger"
  end

  # Optional: force HTTPS behind a proxy/LB
  if config_env() == :prod do
    plug Plug.SSL, rewrite_on: [:x_forwarded_proto]
  end

  # WebSockets
  socket "/socket", ChatServerWeb.UserSocket,
    websocket: (if @ws_origin_opts == [], do: true, else: @ws_origin_opts),
    longpoll: false

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]] ++ @ws_origin_opts,
    longpoll: false

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  # CORS (env-based)
  plug CORSPlug, origin: @cors_origins

  plug ChatServerWeb.Router
end

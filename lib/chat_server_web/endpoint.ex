defmodule ChatServerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :chat_server

  # Compile-time env flag (safe in releases)
  @is_prod Mix.env() == :prod

  @session_options [
    store: :cookie,
    key: "_chat_server_key",
    signing_salt: "UAUXXkdQ",
    same_site: "Lax",
    secure: @is_prod
  ]

  # Compute WS origin opts at compile time
  @ws_origin_opts if @is_prod, do: [check_origin: [System.get_env("PHX_HOST")]], else: []

  # Compute CORS origins at compile time
  @cors_origins case @is_prod do
                  true ->
                    System.get_env("CORS_ORIGINS")
                    |> to_string()
                    |> String.split(~r/\s*,\s*/, trim: true)

                  false ->
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
  if @is_prod do
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

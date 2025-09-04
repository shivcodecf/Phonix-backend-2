defmodule ChatServerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :chat_server

  @session_options [
    store: :cookie,
    key: "_chat_server_key",
    signing_salt: "UAUXXkdQ",
    same_site: "Lax",
    secure: Mix.env() == :prod
  ]

  plug Plug.Static,
    at: "/",
    from: :chat_server,
    gzip: not Application.compile_env(:chat_server, :code_reloader, false),
    only: ChatServerWeb.static_paths(),
    headers: [{"cache-control", "public, max-age=31536000, immutable"}]

  if Application.compile_env(:chat_server, :code_reloader, false) do
    plug Phoenix.CodeReloader
    plug Phoenix.LiveDashboard.RequestLogger,
      param_key: "request_logger",
      cookie_key: "request_logger"
  end

  if Mix.env() == :prod do
    plug Plug.SSL, rewrite_on: [:x_forwarded_proto]
  end

  # WebSockets (no dynamic check_origin yet)
  socket "/socket", ChatServerWeb.UserSocket,
    websocket: true,
    longpoll: false

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
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

  # CORS — allow localhost in dev; in prod allow all for now
  plug CORSPlug, origin: if(Mix.env() == :prod, do: ["*"], else: ["http://localhost:5173"])

  plug ChatServerWeb.Router
end

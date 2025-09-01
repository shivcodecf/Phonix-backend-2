defmodule ChatServerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :chat_server

  @session_options [
    store: :cookie,
    key: "_chat_server_key",
    signing_salt: "UAUXXkdQ",
    same_site: "Lax"
  ]

  # 👇 WebSocket for chat
  socket "/socket", ChatServerWeb.UserSocket,
    websocket: true,
    longpoll: false

  # LiveView socket
  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve static files
  plug Plug.Static,
  at: "/",
  from: :chat_server,
  gzip: not Application.compile_env(:chat_server, :code_reloader, false),
  only: ChatServerWeb.static_paths()

# Enable code reloading in dev
if Application.compile_env(:chat_server, :code_reloader, false) do
  plug Phoenix.CodeReloader
end


  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  # 👇 Allow frontend calls
  plug CORSPlug, origin: ["http://localhost:5173"]

  plug ChatServerWeb.Router
end

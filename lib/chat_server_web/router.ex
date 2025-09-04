pipeline :api do
  plug :accepts, ["json"]
end

pipeline :api_auth do
  plug :accepts, ["json"]
  plug ChatServerWeb.AuthPlug
end

# Public health
scope "/" do
  get "/health", ChatServerWeb.HealthController, :index
end

# Public (if any)
scope "/api", ChatServerWeb do
  pipe_through :api
  # e.g., public endpoints here
end

# Protected
scope "/api", ChatServerWeb do
  pipe_through :api_auth

  get  "/history",     HistoryController, :history
  post "/create_chat", ChatController,    :create
  post "/invite",      ChatController,    :invite
  get  "/my_chats",    ChatController,    :my_chats
end

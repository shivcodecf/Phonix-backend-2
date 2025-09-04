defmodule ChatServerWeb.Router do
  use ChatServerWeb, :router

  # Pipelines
  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug ChatServerWeb.AuthPlug
  end

  # Public health check
  scope "/" do
    get "/health", ChatServerWeb.HealthController, :index
  end

  # (Optional) Public API routes go here
  # scope "/api", ChatServerWeb do
  #   pipe_through :api
  #   get "/status", StatusController, :index
  # end

  # Protected API routes (require Authorization: Bearer <JWT>)
  scope "/api", ChatServerWeb do
    pipe_through :api_auth

    get  "/history",     HistoryController, :history
    post "/create_chat", ChatController,    :create
    post "/invite",      ChatController,    :invite
    get  "/my_chats",    ChatController,    :my_chats
  end
end

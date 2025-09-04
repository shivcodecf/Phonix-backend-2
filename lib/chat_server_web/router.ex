defmodule ChatServerWeb.Router do
  use ChatServerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Authenticated API (uses the AuthPlug below)
  pipeline :api_auth do
    plug :accepts, ["json"]
    plug ChatServerWeb.AuthPlug
  end

  # Public health check
  scope "/" do
    get "/health", ChatServerWeb.HealthController, :index
  end

  # Public (if you want to keep something open, put it here)
  scope "/api", ChatServerWeb do
    pipe_through :api
    # Example: a public "status" endpoint could live here
    # get "/status", StatusController, :index
  end

  # Protected routes (require valid Supabase JWT)
  scope "/api", ChatServerWeb do
    pipe_through :api_auth

    # ✅ Fetch chat history
    get "/history", HistoryController, :history

    # ✅ Create a new chat
    post "/create_chat", ChatController, :create

    # ✅ Invite members by email
    post "/invite", ChatController, :invite

    # ✅ List all chats for logged-in user
    get "/my_chats", ChatController, :my_chats
  end
end

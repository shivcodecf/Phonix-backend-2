defmodule ChatServerWeb.Router do
  use ChatServerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ChatServerWeb do
    pipe_through :api

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

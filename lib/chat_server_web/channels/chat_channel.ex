defmodule ChatServerWeb.ChatChannel do
  use Phoenix.Channel
  alias ChatServerWeb.Presence

  def join("chat:" <> chat_id, _params, socket) do
    user_id = socket.assigns[:user_id]

    # Ensure membership exists
    ensure_membership(chat_id, user_id)

    # Track presence after join
    send(self(), :after_join)

    {:ok, assign(socket, :chat_id, chat_id)}
  end

  # Handle presence after join
  def handle_info(:after_join, socket) do
    user_id = socket.assigns[:user_id]

    # Track this user in Presence
    {:ok, _} =
      Presence.track(socket, user_id, %{
        online_at: System.system_time(:second)
      })

    # Push the full presence state to this user
    push(socket, "presence_state", Presence.list(socket))

    {:noreply, socket}
  end

  # 👇 Handle incoming messages
  def handle_in("new_message", %{"content" => content}, socket) do
    user_id = socket.assigns[:user_id]
    chat_id = socket.assigns[:chat_id]

    # Build message
    msg = %{
      chat_id: chat_id,
      sender_id: user_id,
      content: content,
      inserted_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    # Broadcast to everyone in the room
    broadcast!(socket, "new_message", msg)

    # Persist in Supabase
    persist_message(msg)

    {:noreply, socket}
  end

  defp persist_message(msg) do
    url = Application.fetch_env!(:chat_server, :supabase_url) <> "/rest/v1/messages"

    headers = [
      {"apikey", Application.fetch_env!(:chat_server, :supabase_service_key)},
      {"Authorization", "Bearer " <> Application.fetch_env!(:chat_server, :supabase_service_key)},
      {"Content-Type", "application/json"}
    ]

    body = Jason.encode!(msg)

    Finch.build(:post, url, headers, body)
    |> Finch.request(ChatServerFinch)
  end

  defp ensure_membership(chat_id, user_id) do
    url = Application.fetch_env!(:chat_server, :supabase_url) <> "/rest/v1/chat_members"

    headers = [
      {"apikey", Application.fetch_env!(:chat_server, :supabase_service_key)},
      {"Authorization", "Bearer " <> Application.fetch_env!(:chat_server, :supabase_service_key)},
      {"Content-Type", "application/json"}
    ]

    body = Jason.encode!(%{
      chat_id: chat_id,
      user_id: user_id
    })

    Finch.build(:post, url, headers, body)
    |> Finch.request(ChatServerFinch)
  end
end

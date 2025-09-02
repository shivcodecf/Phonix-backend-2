defmodule ChatServerWeb.ChatChannel do
  use Phoenix.Channel
  alias ChatServerWeb.Presence

  def join("chat:" <> chat_id, _params, socket) do
    user_id = socket.assigns[:user_id]

    # Ensure membership exists (safe)
    ensure_membership(chat_id, user_id)

    # Track presence after join
    send(self(), :after_join)

    {:ok, assign(socket, :chat_id, chat_id)}
  end

  # Handle presence after join
  def handle_info(:after_join, socket) do
    user_id = socket.assigns[:user_id]

    {:ok, _} =
      Presence.track(socket, user_id, %{
        online_at: System.system_time(:second)
      })

    push(socket, "presence_state", Presence.list(socket))

    {:noreply, socket}
  end

  # 👇 Handle incoming messages
  def handle_in("new_message", %{"content" => content}, socket) do
    user_id = socket.assigns[:user_id]
    chat_id = socket.assigns[:chat_id]

    msg = %{
      chat_id: chat_id,
      sender_id: user_id,
      content: content,
      inserted_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    broadcast!(socket, "new_message", msg)
    ChatServer.MessageBuffer.enqueue(msg)

    {:noreply, socket}
  end

  # 👇 Safer ensure_membership
  defp ensure_membership(nil, _), do: :noop
  defp ensure_membership(_, nil), do: :noop

  defp ensure_membership(chat_id, user_id) do
    env = Application.get_all_env(:chat_server)
    IO.inspect(env, label: "⚡ ChatServer ENV")

    supabase_url = Keyword.get(env, :supabase_url)
    service_key  = Keyword.get(env, :supabase_service_key)

    if supabase_url && service_key do
      url = supabase_url <> "/rest/v1/chat_members"

      headers = [
        {"apikey", service_key},
        {"Authorization", "Bearer " <> service_key},
        {"Content-Type", "application/json"}
      ]

      body = Jason.encode!(%{chat_id: chat_id, user_id: user_id})

      Finch.build(:post, url, headers, body)
      |> Finch.request(ChatServerFinch)
      |> case do
        {:ok, %Finch.Response{status: 201}} ->
          IO.puts("✅ Membership ensured for user #{user_id} in chat #{chat_id}")

        {:ok, %Finch.Response{status: code, body: body}} ->
          IO.puts("❌ Failed to ensure membership (#{code}): #{body}")

        {:error, err} ->
          IO.puts("❌ Error ensuring membership: #{inspect(err)}")
      end
    else
      IO.puts("❌ Supabase config missing! supabase_url=#{inspect(supabase_url)} service_key=#{inspect(service_key)}")
    end
  end
end

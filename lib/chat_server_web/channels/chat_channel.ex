defmodule ChatServerWeb.ChatChannel do
  use Phoenix.Channel
  alias ChatServerWeb.Presence

  @max_msg_len 4000

  @impl true
  def join("chat:" <> chat_id, _params, socket) do
    case socket.assigns[:user_id] do
      nil ->
        {:error, %{reason: "unauthorized"}}

      user_id ->
        # TODO: optionally verify they already belong to this chat_id before allowing join.
        Task.Supervisor.start_child(ChatServer.TaskSup, fn ->
          ensure_membership(chat_id, user_id)
        end)

        send(self(), :after_join)
        {:ok, assign(socket, :chat_id, chat_id)}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    user_id = socket.assigns[:user_id]

    {:ok, _} =
      Presence.track(socket, user_id, %{
        online_at: System.system_time(:second)
      })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  @impl true
  def handle_in("new_message", %{"content" => content}, socket) when is_binary(content) do
    content = String.trim(content)

    cond do
      content == "" ->
        {:reply, {:error, %{error: "empty_message"}}, socket}

      String.length(content) > @max_msg_len ->
        {:reply, {:error, %{error: "message_too_long"}}, socket}

      true ->
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
  end

  @impl true
  def handle_in("new_message", _params, socket) do
    {:reply, {:error, %{error: "invalid_payload"}}, socket}
  end

  # ---- helpers ----

  defp ensure_membership(nil, _), do: :noop
  defp ensure_membership(_, nil), do: :noop

  defp ensure_membership(chat_id, user_id) do
    supabase_url = Application.get_env(:chat_server, :supabase_url)
    service_key  = Application.get_env(:chat_server, :supabase_service_key)

    with true <- is_binary(supabase_url) and is_binary(service_key) do
      url = supabase_url <> "/rest/v1/chat_members"

      headers = [
        {"apikey", service_key},
        {"Authorization", "Bearer " <> service_key},
        {"Content-Type", "application/json"},
        {"Prefer", "resolution=ignore-duplicates"}
      ]

      body = Jason.encode!(%{chat_id: chat_id, user_id: user_id})

      Finch.build(:post, url, headers, body)
      |> Finch.request(ChatServerFinch, receive_timeout: 5_000, pool_timeout: 2_000)
      |> case do
        {:ok, %Finch.Response{status: 201}} -> :ok
        {:ok, %Finch.Response{status: code, body: body}} ->
          IO.warn("ensure_membership failed status=#{code} body=#{inspect(body)}")
        {:error, err} ->
          IO.warn("ensure_membership http_error=#{inspect(err)}")
      end
    else
      _ -> IO.warn("Supabase config missing (supabase_url/service_key)")
    end
  end
end

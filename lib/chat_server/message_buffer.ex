defmodule ChatServer.MessageBuffer do
  use GenServer

  @flush_interval 1000
  @batch_size 500

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  def enqueue(msg), do: GenServer.cast(__MODULE__, {:enqueue, msg})

  def init(_) do
    Process.send_after(self(), :flush, @flush_interval)
    {:ok, %{queue: []}}
  end

  def handle_cast({:enqueue, msg}, %{queue: q} = state) do
    {:noreply, %{state | queue: [msg | q]}}
  end

  def handle_info(:flush, %{queue: q} = state) do
    if q != [] do
      batch = Enum.take(q, @batch_size)
      rest = Enum.drop(q, @batch_size)
      send_batch_to_supabase(batch)
      state = %{state | queue: rest}
      Process.send_after(self(), :flush, @flush_interval)
      {:noreply, state}
    else
      Process.send_after(self(), :flush, @flush_interval)
      {:noreply, state}
    end
  end

  defp send_batch_to_supabase(messages) do
    Task.start(fn ->
      url = "#{Application.fetch_env!(:chat_server, :supabase_url)}/functions/v1/write_batch"
      key = Application.fetch_env!(:chat_server, :supabase_service_key)

      headers = [
        {"Content-Type", "application/json"},
        {"Authorization", "Bearer #{key}"},
        {"apikey", key}
      ]

      body = Jason.encode!(%{messages: messages})
      Finch.build(:post, url, headers, body) |> Finch.request(ChatServerFinch)
    end)
  end
end

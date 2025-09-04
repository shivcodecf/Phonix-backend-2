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

      # ✅ spawn async task to send batch
      Task.start(fn -> send_batch_to_supabase(batch) end)

      Process.send_after(self(), :flush, @flush_interval)
      {:noreply, %{state | queue: rest}}
    else
      Process.send_after(self(), :flush, @flush_interval)
      {:noreply, state}
    end
  end

  defp send_batch_to_supabase(messages) do
    url     = "#{Application.fetch_env!(:chat_server, :supabase_url)}/functions/v1/write_batch"
    secret  = Application.fetch_env!(:chat_server, :edge_function_secret)
    service = Application.fetch_env!(:chat_server, :supabase_service_key)

    headers = [
      {"Content-Type", "application/json"},
      {"x-secret", secret},                             # custom auth check inside your Edge Function
      {"Authorization", "Bearer " <> service},          # required by Supabase gateway
      {"apikey", service}                               # required by Supabase gateway
    ]

    body = Jason.encode!(%{messages: messages})

    case Finch.build(:post, url, headers, body) |> Finch.request(ChatServerFinch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        IO.puts("✅ Batch persisted: #{body}")

      {:ok, %Finch.Response{status: code, body: body}} ->
        IO.puts("❌ Failed to persist batch (#{code}): #{body}")

      {:error, err} ->
        IO.puts("❌ Error sending batch: #{inspect(err)}")
    end
  end
end

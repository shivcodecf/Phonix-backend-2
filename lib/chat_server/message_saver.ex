defmodule ChatServer.MessageSaver do
  @supabase_url Application.compile_env!(:chat_server, :supabase_url)
  @supabase_service_key Application.compile_env!(:chat_server, :supabase_service_key)

  def save_message(chat_id, sender_id, content) do
    body = Jason.encode!(%{
      chat_id: chat_id,
      sender_id: sender_id,
      content: content,
      inserted_at: DateTime.utc_now()
    })

    headers = [
      {"apikey", @supabase_service_key},
      {"authorization", "Bearer #{@supabase_service_key}"},
      {"content-type", "application/json"}
    ]

    Req.post!("#{@supabase_url}/rest/v1/messages",
      body: body,
      headers: headers,
      params: [return: "minimal"]
    )
  end
end

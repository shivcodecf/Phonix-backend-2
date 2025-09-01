defmodule ChatServerWeb.HistoryController do
  use ChatServerWeb, :controller

  def history(conn, %{"chat_id" => chat_id}) do
    # Extract token from header (user JWT)
    user_token =
      conn
      |> get_req_header("authorization")
      |> List.first()
      |> to_string()
      |> String.replace("Bearer ", "")

    body = Jason.encode!(%{chat_id: chat_id, limit: 100})

    url =
      Application.fetch_env!(:chat_server, :supabase_url) <>
        "/functions/v1/get_chat_history"

    headers =
      if user_token != "" do
        [
          {"Content-Type", "application/json"},
          {"apikey", Application.fetch_env!(:chat_server, :supabase_anon_key)},
          {"Authorization", "Bearer " <> user_token}
        ]
      else
        # fallback to service key (dev only!)
        [
          {"Content-Type", "application/json"},
          {"apikey", Application.fetch_env!(:chat_server, :supabase_service_key)},
          {"Authorization", "Bearer " <> Application.fetch_env!(:chat_server, :supabase_service_key)}
        ]
      end

    case Finch.request(Finch.build(:post, url, headers, body), ChatServerFinch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        json(conn, Jason.decode!(body))

      {:ok, %Finch.Response{status: code, body: body}} ->
        conn |> put_status(code) |> json(%{error: body})

      {:error, err} ->
        conn |> put_status(500) |> json(%{error: inspect(err)})
    end
  end
end

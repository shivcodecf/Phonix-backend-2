defmodule ChatServerWeb.ChatController do
  use ChatServerWeb, :controller

  # POST /api/create_chat
  # Create a chat owned by the logged-in user
  def create(conn, %{"name" => name}) do
    user_id = conn.assigns.current_user_id

    url = Application.fetch_env!(:chat_server, :supabase_url) <> "/rest/v1/chats"
    sk  = Application.fetch_env!(:chat_server, :supabase_service_key)

    # include owner_id so you can enforce ownership rules later
    body = Jason.encode!(%{name: name, owner_id: user_id})

    headers = [
      {"apikey", sk},
      {"Authorization", "Bearer " <> sk},    # service key for privileged write
      {"Content-Type", "application/json"},
      {"Prefer", "return=representation"}
    ]

    case Finch.build(:post, url, headers, body) |> Finch.request(ChatServerFinch) do
      {:ok, %Finch.Response{status: 201, body: resp}} ->
        json(conn, Jason.decode!(resp))

      {:ok, %Finch.Response{status: code, body: resp}} ->
        conn |> put_status(code) |> json(%{error: resp})

      {:error, err} ->
        conn |> put_status(500) |> json(%{error: inspect(err)})
    end
  end

  # POST /api/invite
  # Invite users (by email) into an existing chat
  def invite(conn, %{"chat_id" => chat_id, "emails" => emails}) do
    sk  = Application.fetch_env!(:chat_server, :supabase_service_key)
    base = Application.fetch_env!(:chat_server, :supabase_url)

    headers = [
      {"apikey", sk},
      {"Authorization", "Bearer " <> sk},
      {"Content-Type", "application/json"},
      {"Prefer", "return=representation"}
    ]

    # look up users in profiles by email
    # NOTE: if emails can contain commas/quotes, consider using RPC instead of this filter
    profile_url = base <> "/rest/v1/profiles?email=in.(" <> Enum.join(emails, ",") <> ")"

    with {:ok, %Finch.Response{status: 200, body: body}} <-
           Finch.build(:get, profile_url, headers) |> Finch.request(ChatServerFinch) do
      profiles = Jason.decode!(body)

      if profiles == [] do
        conn |> put_status(404) |> json(%{error: "No users found"})
      else
        inserts = Enum.map(profiles, &%{chat_id: chat_id, user_id: &1["id"]})
        member_url = base <> "/rest/v1/chat_members"
        body = Jason.encode!(inserts)

        case Finch.build(:post, member_url, headers, body) |> Finch.request(ChatServerFinch) do
          {:ok, %Finch.Response{status: 201, body: resp}} ->
            json(conn, Jason.decode!(resp))

          {:ok, %Finch.Response{status: code, body: resp}} ->
            conn |> put_status(code) |> json(%{error: resp})

          {:error, err} ->
            conn |> put_status(500) |> json(%{error: inspect(err)})
        end
      end
    else
      {:ok, %Finch.Response{status: code, body: resp}} ->
        conn |> put_status(code) |> json(%{error: resp})

      {:error, err} ->
        conn |> put_status(500) |> json(%{error: inspect(err)})
    end
  end

  # GET /api/my_chats
  # Read with the user's JWT so RLS only returns their chats
  def my_chats(conn, _params) do
    user_token = conn.assigns.bearer_token

    url =
      Application.fetch_env!(:chat_server, :supabase_url) <>
        "/rest/v1/chats?select=id,name,chat_members!inner(user_id)"

    headers = [
      {"apikey", Application.fetch_env!(:chat_server, :supabase_service_key)},
      {"Authorization", "Bearer " <> user_token}
    ]

    case Finch.build(:get, url, headers) |> Finch.request(ChatServerFinch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        json(conn, Jason.decode!(body))

      {:ok, %Finch.Response{status: code, body: body}} ->
        conn |> put_status(code) |> json(%{error: body})

      {:error, err} ->
        conn |> put_status(500) |> json(%{error: inspect(err)})
    end
  end
end

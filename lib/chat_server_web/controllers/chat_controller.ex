defmodule ChatServerWeb.ChatController do
  use ChatServerWeb, :controller

  # ✅ Create a new chat
  def create(conn, %{"name" => name}) do
    user_token =
      conn
      |> get_req_header("authorization")
      |> List.first()
      |> to_string()
      |> String.replace("Bearer ", "")
      


    url = Application.fetch_env!(:chat_server, :supabase_url) <> "/rest/v1/chats"


    body = Jason.encode!(%{name: name}) 



    headers = [
      {"apikey", Application.fetch_env!(:chat_server, :supabase_service_key)},
      {"Authorization", "Bearer " <> Application.fetch_env!(:chat_server, :supabase_service_key)},
      {"Content-Type", "application/json"},
      {"Prefer", "return=representation"}
    ]



    case Finch.build(:post, url, headers, body) |> Finch.request(ChatServerFinch) do
      {:ok, %Finch.Response{status: 201, body: body}} ->
        chat = Jason.decode!(body)
        json(conn, chat)

      {:ok, %Finch.Response{status: code, body: body}} ->
        conn |> put_status(code) |> json(%{error: body})

      {:error, err} ->
        conn |> put_status(500) |> json(%{error: inspect(err)})
    end
  end

  # ✅ Invite users by email into an existing chat
  def invite(conn, %{"chat_id" => chat_id, "emails" => emails}) do
    service_key = Application.fetch_env!(:chat_server, :supabase_service_key)
    url = Application.fetch_env!(:chat_server, :supabase_url)

    headers = [
      {"apikey", service_key},
      {"Authorization", "Bearer " <> service_key},
      {"Content-Type", "application/json"},
      {"Prefer", "return=representation"}
    ]

    # look up users in profiles by email
    profile_url = url <> "/rest/v1/profiles?email=in.(" <> Enum.join(emails, ",") <> ")"

    with {:ok, %Finch.Response{status: 200, body: body}} <-
           Finch.build(:get, profile_url, headers) |> Finch.request(ChatServerFinch) do
      profiles = Jason.decode!(body)

      if profiles == [] do
        conn |> put_status(404) |> json(%{error: "No users found"})
      else
        inserts =
          profiles
          |> Enum.map(fn p -> %{chat_id: chat_id, user_id: p["id"]} end)

        member_url = url <> "/rest/v1/chat_members"
        body = Jason.encode!(inserts)

        case Finch.build(:post, member_url, headers, body) |> Finch.request(ChatServerFinch) do
          {:ok, %Finch.Response{status: 201, body: body}} ->
            json(conn, Jason.decode!(body))

          {:ok, %Finch.Response{status: code, body: body}} ->
            conn |> put_status(code) |> json(%{error: body})

          {:error, err} ->
            conn |> put_status(500) |> json(%{error: inspect(err)})
        end
      end
    else
      {:ok, %Finch.Response{status: code, body: body}} ->
        conn |> put_status(code) |> json(%{error: body})

      {:error, err} ->
        conn |> put_status(500) |> json(%{error: inspect(err)})
    end
  end

  # ✅ Fetch all chats that the current user belongs to
  def my_chats(conn, _params) do
    user_token =
      conn
      |> get_req_header("authorization")
      |> List.first()
      |> to_string()
      |> String.replace("Bearer ", "")

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

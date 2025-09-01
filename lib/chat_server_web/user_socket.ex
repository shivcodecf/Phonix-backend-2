defmodule ChatServerWeb.UserSocket do
  use Phoenix.Socket
  alias JOSE.JWT

  channel "chat:*", ChatServerWeb.ChatChannel

  def connect(%{"token" => token}, socket, _connect_info) do
    case verify_token(token) do
      {:ok, claims} ->
        # 👇 use `sub` claim (Supabase user UUID)
        {:ok, assign(socket, :user_id, claims["sub"])}
      {:error, _} ->
        :error
    end
  end

  defp verify_token(token) do
    secret = Application.fetch_env!(:chat_server, :supabase_jwt_secret)
    case JWT.verify_strict(JOSE.JWK.from_oct(secret), ["HS256"], token) do
      {true, %JOSE.JWT{fields: claims}, _} -> {:ok, claims}
      _ -> {:error, :invalid}
    end
  end

  def id(socket), do: "users:#{socket.assigns.user_id}"
end

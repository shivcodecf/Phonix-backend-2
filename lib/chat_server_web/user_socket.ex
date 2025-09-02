defmodule ChatServerWeb.UserSocket do
  use Phoenix.Socket
  alias JOSE.JWT

  channel "chat:*", ChatServerWeb.ChatChannel

  def connect(%{"token" => token}, socket, _connect_info) do
    case verify_token(token) do
      {:ok, claims} ->
        IO.inspect(claims, label: "✅ Decoded Supabase JWT claims")

        user_id =
          claims["sub"] ||
          claims["user_id"] ||
          claims["id"] ||
          get_in(claims, ["user", "id"])

        if user_id do
          {:ok, assign(socket, :user_id, user_id)}
        else
          IO.puts("❌ No valid user_id found in claims")
          :error
        end

      {:error, _} ->
        :error
    end
  end

  defp verify_token(token) do
    secret = Application.fetch_env!(:chat_server, :supabase_jwt_secret)

    case JWT.verify_strict(JOSE.JWK.from_oct(secret), ["HS256"], token) do
      {true, %JOSE.JWT{fields: claims}, _} ->
        {:ok, claims}

      err ->
        IO.inspect(err, label: "❌ JWT verification failed")
        {:error, :invalid}
    end
  end

  def id(socket), do: "users:#{socket.assigns.user_id}"
end

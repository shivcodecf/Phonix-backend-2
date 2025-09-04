defmodule ChatServerWeb.UserSocket do
  use Phoenix.Socket
  alias Joken.Signer

  channel "chat:*", ChatServerWeb.ChatChannel

  def connect(%{"token" => token}, socket, _connect_info) when is_binary(token) do
    case verify_token(token) do
      {:ok, claims} ->
        user_id = claims["sub"] || claims["user_id"] || claims["id"]
        if user_id, do: {:ok, assign(socket, :user_id, user_id)}, else: :error

      {:error, _} ->
        :error
    end
  end

  def connect(_, _, _), do: :error

  def id(socket), do: "users:#{socket.assigns.user_id}"

  # 👇 This is the function you pasted
  defp verify_token(token) do
    secret = Application.fetch_env!(:chat_server, :supabase_jwt_secret)
    signer = Signer.create("HS256", secret)

    case Joken.verify(token, signer) do
      {:ok, claims} ->
        claims =
          case claims do
            %{"exp" => exp} when is_integer(exp) ->
              now = System.os_time(:second)
              if exp < now, do: :expired, else: claims

            _ -> claims
          end

        if claims == :expired, do: {:error, :expired}, else: {:ok, claims}

      {:error, reason} ->
        {:error, reason}
    end
  end
end

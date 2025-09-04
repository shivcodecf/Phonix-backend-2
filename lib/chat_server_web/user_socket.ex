defmodule ChatServerWeb.UserSocket do
  use Phoenix.Socket
  alias Joken.Signer

  ## Channels
  channel "chat:*", ChatServerWeb.ChatChannel

  # Client must pass ?token=... in socket params
  # Example (JS): new Socket("/socket", {params: {token: jwt}})
  def connect(%{"token" => token}, socket, _connect_info) when is_binary(token) do
    case verify_token(token) do
      {:ok, claims} ->
        maybe_log_claims(claims)

        user_id =
          claims["sub"] ||
          claims["user_id"] ||
          claims["id"] ||
          get_in(claims, ["user", "id"])

        if user_id do
          {:ok, assign(socket, :user_id, user_id)}
        else
          :error
        end

      {:error, _reason} ->
        :error
    end
  end

  # No token → refuse connection
  def connect(_params, _socket, _connect_info), do: :error

  # Each user gets their own socket id topic for disconnects/broadcasts
  def id(socket), do: "users:#{socket.assigns.user_id}"

  # -------- helpers --------

  defp verify_token(token) do
    # Your Supabase JWT secret must be set in env and loaded into runtime.exs
    secret = Application.fetch_env!(:chat_server, :supabase_jwt_secret)
    signer = Signer.create("HS256", secret)

    case Joken.verify(token, signer) do
      {:ok, claims} ->
        # Basic exp check (Joken can be configured to validate standard claims;
        # this is a simple guard if you didn't set a Joken config module)
        case claims do
          %{"exp" => exp} when is_integer(exp) and exp < System.os_time(:second) ->
            {:error, :expired}

          _ ->
            {:ok, claims}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_log_claims(claims) do
    # Helpful in dev, avoid in prod to not leak info
    if Mix.env() != :prod do
      IO.inspect(claims, label: "✅ Decoded Supabase JWT claims")
    end
  end
end

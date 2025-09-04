defmodule ChatServerWeb.AuthPlug do
  @moduledoc """
  Verifies `Authorization: Bearer <JWT>` using SUPABASE_JWT_SECRET.

  On success assigns:
    - `conn.assigns.current_user`     → full JWT claims
    - `conn.assigns.current_user_id`  → user id extracted from claims
    - `conn.assigns.bearer_token`     → the raw token (for RLS queries)
  """
  @behaviour Plug

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]
  alias Joken.Signer

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, claims} <- verify(token),
         user_id when is_binary(user_id) <- extract_user_id(claims) do
      conn
      |> assign(:current_user, claims)
      |> assign(:current_user_id, user_id)
      |> assign(:bearer_token, token)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "unauthorized"})
        |> halt()
    end
  end

  # --------------------------
  # Helpers
  # --------------------------

  defp verify(token) do
    secret = Application.fetch_env!(:chat_server, :supabase_jwt_secret)
    signer = Signer.create("HS256", secret)

    case Joken.verify(token, signer) do
      {:ok, %{"exp" => exp} = claims} when is_integer(exp) ->
        if exp < System.os_time(:second), do: {:error, :expired}, else: {:ok, claims}

      {:ok, claims} ->
        {:ok, claims}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_user_id(claims) do
    claims["sub"] ||
      claims["user_id"] ||
      claims["id"] ||
      get_in(claims, ["user", "id"])
  end
end

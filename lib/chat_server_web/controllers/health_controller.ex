defmodule ChatServerWeb.HealthController do
  use ChatServerWeb, :controller

  def index(conn, _params) do
    # Respond with plain text so Render health checks pass
    text(conn, "ok")
  end
end

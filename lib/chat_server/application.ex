defmodule ChatServer.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ChatServerWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:chat_server, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ChatServer.PubSub},
      {Finch, name: ChatServerFinch}, # ✅ for Supabase HTTP requests
      ChatServerWeb.Endpoint,
       ChatServerWeb.Presence
    ]

    opts = [strategy: :one_for_one, name: ChatServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ChatServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

defmodule ExMetrc.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children =
      [
        # Start the PubSub system
        {Phoenix.PubSub, name: ExMetrc.PubSub},
        # Start the Endpoint (http/https)
        ExMetrcWeb.Endpoint
        # Start a worker by calling: ExMetrc.Worker.start_link(arg)
        # {ExMetrc.Worker, arg}
      ]
      |> append_if(
        Application.get_env(:ex_metrc, :env) != :test,
        {Tz.UpdatePeriodically, []}
      )

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExMetrc.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ExMetrcWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp append_if(list, condition, item) do
    if condition, do: list ++ [item], else: list
  end
end

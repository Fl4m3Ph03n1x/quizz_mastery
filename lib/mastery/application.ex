defmodule Mastery.Application do
  @moduledoc false

  use Application

  alias Mastery.Boundary.QuizManager
  alias Mastery.Registry.QuizSession, as: RQSession
  alias Mastery.Supervisor.QuizSession, as: SQSession

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    children = [
      {QuizManager,       [name: QuizManager]},
      {Registry,          [name: RQSession, keys: :unique]},
      {DynamicSupervisor, [name: SQSession, strategy: :one_for_one]}
    ]

    opts = [strategy: :one_for_one, name: Mastery.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

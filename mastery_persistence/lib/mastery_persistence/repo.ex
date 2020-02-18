defmodule MasteryPersistence.Repo do
  @moduledoc """
  Adapter for the postgres DB.
  """

  use Ecto.Repo,
    otp_app: :mastery_persistence,
    adapter: Ecto.Adapters.Postgres

end

defmodule MasteryPersistence.MixProject do
  use Mix.Project

  def project do
    [
      app: :mastery_persistence,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MasteryPersistence.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.1"},
      {:postgrex, "~> 0.14.1"},

      # Dev
      {:credo,          "~> 1.1.0",       only: [:dev, :test],  runtime: false},
      {:dialyxir,       "~> 1.0.0-rc.7",  only: [:dev],         runtime: false}
    ]
  end
end

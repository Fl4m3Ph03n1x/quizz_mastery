defmodule Mastery.MixProject do
  use Mix.Project

  def project do
    [
      app: :mastery,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :eex],
      mod: {Mastery.Application, []}
    ]
  end

  defp deps do
    [
      {:typed_struct,         "~> 0.1.4"},
      {:mastery_persistence,  path: "mastery_persistence"},

      # Dev
      {:credo,          "~> 1.1.0",       only: [:dev, :test],  runtime: false},
      {:mix_test_watch, "~> 0.8",         only: [:dev],         runtime: false},
      {:dialyxir,       "~> 1.0.0-rc.7",  only: [:dev],         runtime: false}
    ]
  end
end

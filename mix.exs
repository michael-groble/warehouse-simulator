defmodule WarehouseSimulator.MixProject do
  use Mix.Project

  def project do
    [
      app: :warehouse_simulator,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {WarehouseSimulator, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.1"}
    ]
  end

  defp escript do
    [
      main_module: WarehouseSimulator.CLI,
      path: "_build/#{Mix.env()}/warehouse_simulator"
    ]
  end
end

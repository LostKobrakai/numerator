defmodule Numerator.MixProject do
  use Mix.Project

  def project do
    [
      app: :numerator,
      version: "0.2.0",
      elixir: "~> 1.7",
      name: "Numerator",
      source_url: "https://github.com/madeitGmbH/numerator",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:excoveralls, "~> 0.10", only: :test},
      {:stream_data, "~> 0.1", only: :test},
      {:dialyxir, "~> 1.0-rc", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:benchee, "~> 1.0", only: :dev}
    ]
  end

  defp description() do
    "Numerator does calculate paginations without creating any markup."
  end

  defp docs do
    [
      extras: ["README.md"]
    ]
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/madeitGmbH/numerator"}
    ]
  end
end

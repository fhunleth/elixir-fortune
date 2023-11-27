defmodule Fortune.MixProject do
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/fhunleth/elixir-fortune"

  def project() do
    [
      app: :fortune,
      version: @version,
      elixir: "~> 1.11",
      docs: docs(),
      description: description(),
      package: package(),
      deps: deps(),
      dialyzer: dialyzer(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs
      }
    ] ++ test_options(Mix.env())
  end

  def application() do
    [
      extra_applications: []
    ]
  end

  # Only run the fortune compiler for dev and test
  # The prod version doesn't include any fortunes.
  def test_options(env) when env in [:dev, :test] do
    [compilers: Mix.compilers() ++ [:fortune_compiler], fortunec_paths: ["test/support/fortune"]]
  end

  def test_options(_env), do: []

  defp deps() do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.25", only: :docs, runtime: false}
    ]
  end

  defp docs() do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp description() do
    "Get a fortune!"
  end

  defp package() do
    [
      files: ["CHANGELOG.md", "lib", "LICENSES/*", "mix.exs", "README.md"],
      licenses: ["Apache-2.0"],
      links: %{"Github" => @source_url}
    ]
  end

  defp dialyzer() do
    [
      flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling, :underspecs],
      plt_add_apps: [:mix]
    ]
  end
end

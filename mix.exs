defmodule Fortune.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/fhunleth/fortune"

  def project() do
    [
      app: :fortune,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      compilers: compilers(Mix.env()),
      fortune: [inputs: ["test/support/elixir"]],
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
    ]
  end

  def application() do
    [
      extra_applications: []
    ]
  end

  def compilers(env) when env in [:dev, :test] do
    Mix.compilers() ++ [:fortune_compiler]
  end

  def compilers(_env), do: Mix.compilers()

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
    "Fortune file reader for Elixir"
  end

  defp package() do
    [
      files: ["CHANGELOG.md", "lib", "LICENSE", "mix.exs", "README.md"],
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

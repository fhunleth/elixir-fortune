defmodule LibraryA.MixProject do
  use Mix.Project

  def project do
    [
      app: :library_a,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      compilers: Mix.compilers() ++ [:fortune_compiler],
      deps: deps()
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
      {:fortune, path: System.get_env("FORTUNE_PATH", "../..")}
    ]
  end
end

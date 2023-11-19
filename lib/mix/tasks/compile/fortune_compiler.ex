defmodule Mix.Tasks.Compile.FortuneCompiler do
  @moduledoc """
  Build STRFILE-format index files for use by fortune

  The input files should be in a `fortune` directory. Each string or fortune
  should be separated by a `%` line. For example:

  ```text
  My first fortune
  %
  Another string or fortune
  and this can be multiple lines too.
  %
  The last string
  ```
  """
  use Mix.Task

  alias Fortune.StrfileWriter

  @recursive true

  @doc false
  def run(_args) do
    check_priv()

    paths = Mix.Project.config()[:fortune_paths] || ["fortune"]
    inputs = Enum.flat_map(paths, &find_files/1)

    Enum.each(inputs, &process_file/1)
  end

  defp find_files(path) do
    case File.ls(path) do
      {:ok, paths} -> Enum.map(paths, &Path.join(path, &1))
      {:error, _any} -> []
    end
  end

  defp check_priv() do
    priv_path = Path.join([Mix.Project.app_path(), "priv"])

    case File.read_link(priv_path) do
      {:ok, _} ->
        Mix.shell().error("""
        Cannot compile fortunes and use the priv directory at the same time.

        One way of fixing this is to move the contents of the priv directory to
        a different directory, e.g., assets. Then in the `mix.exs`, copy the
        contents of the assets directory to the priv directory at compilation
        time.
        """)

      _ ->
        :ok
    end
  end

  defp process_file(file) do
    priv_path = Path.join([Mix.Project.app_path(), "priv", "fortune"])
    File.mkdir_p!(priv_path)

    StrfileWriter.create(file, priv_path)
  end
end

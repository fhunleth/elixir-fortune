defmodule Fortune do
  @moduledoc false

  alias Fortune.Strfile

  @doc """
  Pick one tip randomly
  """
  @spec random() :: {:ok, String.t()} | {:error, atom()}
  def random() do
    path = fortune_paths() |> Enum.random()

    with {:ok, strfile} <- Strfile.open(path),
         rand_index = :rand.uniform(strfile.header.num_string) - 1,
         {:ok, string} <- Strfile.read_string(strfile, rand_index) do
      _ = Strfile.close(strfile)
      {:ok, string}
    end
  end

  @doc """
  Raising version of random/0
  """
  def random!() do
    case random() do
      {:ok, string} -> string
      {:error, reason} -> raise RuntimeError, "Fortune.random failed with #{reason}"
    end
  end

  @doc """
  Scan search paths for fortune files

  Paths can be passed in to search if you don't want to use the defaults.
  """
  @spec fortune_paths(String.t() | [String.t()] | nil) :: [String.t()]
  def fortune_paths(paths \\ nil) do
    paths =
      case paths do
        path when is_binary(path) -> [path]
        nil -> default_paths()
        paths when is_list(paths) -> paths
      end

    Strfile.search_paths(paths)
  end

  @spec fortune_info(Path.t()) :: {:ok, map()} | {:error, atom()}
  def fortune_info(path) do
    Strfile.read_info(path)
  end

  defp default_paths() do
    Application.loaded_applications()
    |> Enum.map(&elem(&1, 0))
    |> Enum.flat_map(&fortunes_dirs/1)
  end

  defp fortunes_dirs(name) do
    dir = Application.app_dir(name, ["priv", "fortunes"])

    if File.dir?(dir) do
      [dir]
    else
      []
    end
  rescue
    ArgumentError -> []
  end
end

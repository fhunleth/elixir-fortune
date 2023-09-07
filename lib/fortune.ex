defmodule Fortune do
  @moduledoc false

  alias Fortune.Strfile

  @type fortune_option() ::
          {:paths, String.t() | [String.t()] | nil}
          | {:include, atom | [atom] | nil}
          | {:exclude, atom | [atom] | nil}

  @doc """
  Pick one tip randomly
  """
  @spec random() :: {:ok, String.t()} | {:error, atom()}
  def random() do
    options = Application.get_all_env(:fortune)
    path = fortune_paths(options) |> Enum.random()

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
  Scan search paths for fortune files. By default, search for all the fortune
  files that are provided by your Elixir project and its dependencies.

  If you don't want to use the defaults, paths can be passed in to search.

  Alternatively, you can select or reject certain fortunes by providing
  application name atoms as an inclusion list or exclusion list.

  Options:

  * `:paths` - a list of absolute paths to `fortunes` directories
  * `:include` - a list of applications whose fortunes you want to opt in for
  * `:exclude` - a list of applications whose fortunes you want to opt out of
  """
  @spec fortune_paths([fortune_option]) :: [String.t()]
  def fortune_paths(options \\ []) do
    filter_options = Keyword.take(options, [:include, :exclude])

    paths =
      case options[:paths] do
        path when is_binary(path) -> [path]
        nil -> default_paths(filter_options)
        paths when is_list(paths) -> paths
      end

    Strfile.search_paths(paths)
  end

  @spec fortune_info(Path.t()) :: {:ok, map()} | {:error, atom()}
  def fortune_info(path) do
    Strfile.read_info(path)
  end

  defp default_paths(options) do
    fortune_provider_apps(options) |> Enum.flat_map(&fortunes_dirs/1)
  end

  defp fortune_provider_apps(options) do
    inclusion_list = get_filter_option(options, :include)
    exclusion_list = get_filter_option(options, :exclude)
    apps = Application.loaded_applications() |> Enum.map(&elem(&1, 0))

    cond do
      is_list(inclusion_list) ->
        apps |> Enum.filter(&(&1 in inclusion_list))

      is_list(exclusion_list) ->
        apps |> Enum.reject(&(&1 in exclusion_list))

      true ->
        apps
    end
  end

  defp get_filter_option(options, key) do
    case options[key] do
      nil -> nil
      [] -> nil
      values when is_list(values) -> values
      value -> [value]
    end
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

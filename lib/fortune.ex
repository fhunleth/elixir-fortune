defmodule Fortune do
  @moduledoc false

  alias Fortune.StrfileReader

  @typedoc """
  The fortune options

  * `:paths` - a list of absolute paths to `fortune` directories
  * `:include` - specifically include these applications that contain fortunes
  * `:exclude` - exclude these applications from being scanned for fortunes
  """
  @type fortune_option() ::
          [
            paths: String.t() | [String.t()] | nil,
            include: atom | [atom] | nil,
            exclude: atom | [atom] | nil
          ]

  @doc """
  Pick one fortune randomly
  """
  @spec random([fortune_option]) :: {:ok, String.t()} | {:error, atom()}
  def random(options \\ []) do
    options = if options == [], do: Application.get_all_env(:fortune), else: options
    strfiles = fortune_paths(options) |> open_all()

    if strfiles != [] do
      num_fortunes =
        Enum.reduce(strfiles, 0, fn strfile, acc -> acc + strfile.header.num_string end)

      rand_fortune = :rand.uniform(num_fortunes - 1)
      result = nth_fortune(strfiles, rand_fortune)

      Enum.each(strfiles, &StrfileReader.close/1)
      result
    else
      {:error, :no_fortunes}
    end
  end

  defp nth_fortune([strfile | rest], n) do
    if n >= strfile.header.num_string do
      nth_fortune(rest, n - strfile.header.num_string)
    else
      StrfileReader.read_string(strfile, n)
    end
  end

  defp open_all(paths, acc \\ [])
  defp open_all([], acc), do: acc

  defp open_all([path | rest], acc) do
    case StrfileReader.open(path) do
      {:ok, info} -> open_all(rest, [info | acc])
      {:error, _} -> open_all(rest, acc)
    end
  end

  @doc """
  Raising version of random/0
  """
  def random!(options \\ []) do
    case random(options) do
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

    StrfileReader.search_paths(paths)
  end

  @spec fortune_info(Path.t()) :: {:ok, map()} | {:error, atom()}
  def fortune_info(path) do
    StrfileReader.read_info(path)
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
    dir = Application.app_dir(name, ["priv", "fortune"])

    if File.dir?(dir) do
      [dir]
    else
      []
    end
  rescue
    ArgumentError -> []
  end
end

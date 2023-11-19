defmodule Fortune.Finder do
  @moduledoc false

  alias Fortune.StrfileReader

  @doc """
  Scan search paths for fortune files. By default, search for all the fortune
  files that are provided by your Elixir project and its dependencies.

  If you don't want to use the defaults, paths can be passed in to search.

  Alternatively, you can select or reject certain fortunes by providing
  application name atoms as an inclusion list or exclusion list.
  """
  @spec fortune_paths(Fortune.fortune_options()) :: [String.t()]
  def fortune_paths(options \\ []) do
    filter_options = Keyword.take(options, [:included_applications, :excluded_applications])

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
    inclusion_list = get_filter_option(options, :included_applications)
    exclusion_list = get_filter_option(options, :excluded_applications)
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

    if File.dir?(dir), do: [dir], else: []
  rescue
    ArgumentError -> []
  end
end

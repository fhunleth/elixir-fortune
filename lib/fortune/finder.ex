# SPDX-FileCopyrightText: 2023 Frank Hunleth, Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fortune.Finder do
  @moduledoc false

  alias Fortune.StrfileReader

  @doc """
  Scan search paths for fortune files.

  By default, this searches the current Elixir project and dependencies for
  fortune files. If nothing is found, it tries to find system fortunes.

  If you don't want to use the defaults, paths can be passed in to search.

  Alternatively, you can select or reject certain fortunes by providing
  application name atoms as an inclusion list or exclusion list.
  """
  @spec fortune_paths(Fortune.fortune_options()) :: [String.t()]
  def fortune_paths(options \\ []) do
    paths =
      case List.wrap(options[:paths]) do
        [] -> default_paths(options)
        paths when is_list(paths) -> paths
      end

    StrfileReader.search_paths(paths)
  end

  defp default_paths(options) do
    Application.loaded_applications()
    |> Enum.map(&elem(&1, 0))
    |> filter_inclusions(options)
    |> filter_exclusions(options)
    |> Enum.flat_map(&app_fortune_dir/1)
    |> add_system_paths(options)
  end

  defp filter_inclusions(apps, options) do
    inclusion_list = get_filter_option(options, :included_applications)
    if inclusion_list, do: Enum.filter(apps, &(&1 in inclusion_list)), else: apps
  end

  defp filter_exclusions(apps, options) do
    exclusion_list = get_filter_option(options, :excluded_applications)
    if exclusion_list, do: Enum.reject(apps, &(&1 in exclusion_list)), else: apps
  end

  defp add_system_paths(paths, options) do
    case options[:include_system_fortunes?] do
      nil -> if paths == [], do: system_dirs(), else: paths
      false -> paths
      true -> paths ++ system_dirs()
    end
  end

  defp system_dirs() do
    [
      "/usr/share/games/fortunes",
      "/usr/local/share/games/fortunes",
      "/opt/homebrew/share/games/fortunes/"
    ]
    |> Enum.filter(&File.dir?/1)
  end

  defp get_filter_option(options, key) do
    case options[key] do
      nil -> nil
      [] -> nil
      values when is_list(values) -> values
      value -> [value]
    end
  end

  defp app_fortune_dir(name) do
    dir = Application.app_dir(name, ["priv", "fortune"])

    if File.dir?(dir), do: [dir], else: []
  rescue
    ArgumentError -> []
  end
end

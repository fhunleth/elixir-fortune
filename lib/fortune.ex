# SPDX-FileCopyrightText: 2023 Frank Hunleth, Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
defmodule Fortune do
  @moduledoc """
  Get a fortune!

  Fortune reads a string, usually a random one, from one or more fortune files.
  Fortune files contain a list of strings and an associated index for for quick
  retrieval of a randomly chosen string. This implementation provides an Elixir
  take on the ubiquitous Unix fortune implementation. It is compatible with
  Unix fortune and can read most Unix fortune files.

  ```elixir
  iex> Fortune.random()
  {:ok, "Harness the power of the BEAM, one Elixir potion at a time."}
  ```

  No fortunes are provided, though. You'll need to add your own, add Elixir
  libraries to your mix dependencies that have fortunes, or use your system's fortunes.

  Fortunes provided by Elixir libraries are stored in that library's
  `priv/fortune` directory. See the `README.md` for using the `:fortune_compiler`
  for adding your own.

  If no Elixir-provided fortunes are found, `fortune` checks the system's
  `/usr/share/games/fortune` directory (and various similar ones)  for fortunes
  to find something.

  See `fortune_options/0` for modifying fortune search paths.
  """

  alias Fortune.Finder
  alias Fortune.StrfileReader

  @typedoc """
  Fortune options

  Pass these to `Fortune.random/1` and similar functions:

  * `:paths` - a list of absolute paths to `fortune` directories or files. Overrides other options
  * `:included_applications` - specifically include these applications that contain fortunes
  * `:excluded_applications` - exclude these applications from being scanned for fortunes
  * `:include_system_fortunes?` - set to `true` to include system fortunes. Defaults to `true` if no Elixir projects supply fortunes.

  To set defaults for your project, add Fortune options to your application's `config.exs`:

  ```elixir
  config :fortune, include_system_fortunes?: true
  ```
  """
  @type fortune_options() ::
          [
            paths: String.t() | [String.t()] | nil,
            included_applications: atom | [atom] | nil,
            excluded_applications: atom | [atom] | nil
          ]

  @doc """
  Return a random fortune

  See `Fortune` for an overview and `fortune_options/0` for modifying fortune
  search paths.
  """
  @spec random(fortune_options) :: {:ok, String.t()} | {:error, atom()}
  def random(options \\ []) do
    with {:ok, strfiles} <- open_all_strfiles(options) do
      num_fortunes = count_fortunes(strfiles)

      rand_fortune = :rand.uniform(num_fortunes - 1)
      result = nth_fortune(strfiles, rand_fortune)

      Enum.each(strfiles, &StrfileReader.close/1)
      result
    end
  end

  defp nth_fortune([strfile | rest], n) do
    if n >= strfile.header.num_string do
      nth_fortune(rest, n - strfile.header.num_string)
    else
      StrfileReader.read_string(strfile, n)
    end
  end

  defp open_all_strfiles(options) do
    merged_options = Keyword.merge(Application.get_all_env(:fortune), options)
    strfiles = merged_options |> Finder.fortune_paths() |> open_all()

    if strfiles != [] do
      {:ok, strfiles}
    else
      {:error, :no_fortunes}
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
  Return a random fortune or raise an exception

  See `Fortune` for an overview and `fortune_options/0` for modifying fortune
  search paths.
  """
  @spec random!(fortune_options()) :: String.t()
  def random!(options \\ []) do
    case random(options) do
      {:ok, string} -> string
      {:error, reason} -> raise RuntimeError, "Fortune.random failed with #{reason}"
    end
  end

  @doc """
  Return statistics on fortunes

  This can be useful for finding out what fortunes are available. The options are
  the same as the ones for `random/1`.

  NOTE: The returned map may change in the future which is why it is untyped.
  """
  @spec info(fortune_options) :: {:ok, map()} | {:error, atom()}
  def info(options \\ []) do
    with {:ok, strfiles} <- open_all_strfiles(options) do
      num_fortunes = count_fortunes(strfiles)
      num_files = Enum.count(strfiles)

      files =
        Enum.reduce(strfiles, %{}, fn strfile, acc ->
          Map.put(acc, strfile.path, %{
            num_string: strfile.header.num_string,
            size: file_size(strfile.path)
          })
        end)

      Enum.each(strfiles, &StrfileReader.close/1)
      {:ok, %{num_fortunes: num_fortunes, num_files: num_files, files: files}}
    end
  end

  defp file_size(path) do
    case File.stat(path) do
      {:ok, stat} -> stat.size
      _ -> -1
    end
  end

  defp count_fortunes(strfiles) do
    Enum.reduce(strfiles, 0, fn strfile, acc -> acc + strfile.header.num_string end)
  end
end

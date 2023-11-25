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
  # Although not necessary, let's seed the random algorithm
  iex> :rand.seed(:exsss, {8, 9, 10})
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
  """
  @spec random(fortune_options) :: {:ok, String.t()} | {:error, atom()}
  def random(options \\ []) do
    merged_options = Keyword.merge(Application.get_all_env(:fortune), options)
    strfiles = merged_options |> Finder.fortune_paths() |> open_all()

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
  Raising version of random/1
  """
  @spec random!(fortune_options()) :: String.t()
  def random!(options \\ []) do
    case random(options) do
      {:ok, string} -> string
      {:error, reason} -> raise RuntimeError, "Fortune.random failed with #{reason}"
    end
  end
end

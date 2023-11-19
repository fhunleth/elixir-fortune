defmodule Fortune do
  @moduledoc """
  Get a fortune!

  Fortune reads a string, usually a random one, from one or more fortune files. Fortune
  files contain a list of strings and an associated index for for quick retrieval of
  a randomly chosen string. This implementation provides an Elixir take on the
  ubiquitous Unix fortune implementation. It is compatible with Unix fortune and can read most Unix fortune files.

  ```elixir
  iex> Fortune.random()
  {:ok, "A fortune would be here!"}
  ```

  No fortunes are provided, though. You'll need to add your own, add Elixir libraries to your
  mix dependencies that have fortunes, or configure Fortune to use your system ones.

  Here's an example on Mac when you've installed `fortune` via Homebrew:

  ```elixir
  iex> Fortune.random(paths: ["/opt/homebrew/share/games/fortunes/"])
  {:ok, "Good luck"}
  ```

  Fortunes provided by Elixir libraries are stored in that library's `priv/fortune` directory
  when using this library's `fortune` compiler. Fortune scans for these paths by default.
  """

  alias Fortune.Finder
  alias Fortune.StrfileReader

  @typedoc """
  Fortune options

  * `:paths` - a list of absolute paths to `fortune` directories or files
  * `:included_applications` - specifically include these applications that contain fortunes
  * `:excluded_applications` - exclude these applications from being scanned for fortunes
  """
  @type fortune_options() ::
          [
            paths: String.t() | [String.t()] | nil,
            included_applications: atom | [atom] | nil,
            excluded_applications: atom | [atom] | nil
          ]

  @doc """
  Pick one fortune randomly
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
  Raising version of random/0
  """
  @spec random!(fortune_options()) :: String.t()
  def random!(options \\ []) do
    case random(options) do
      {:ok, string} -> string
      {:error, reason} -> raise RuntimeError, "Fortune.random failed with #{reason}"
    end
  end
end

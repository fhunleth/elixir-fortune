defmodule Mix.Tasks.Compile.StrfileCompiler do
  @moduledoc """
  Build STRFILE-format index files

  The input files should be in a `fortunes` directory. Each string or fortune
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

  @strfile_version 2
  @strfile_separator ?%

  @recursive true

  defstruct location: 0, num_string: 0, shortest_string: 4096, longest_string: 0, indices: []

  @doc false
  def run(_args) do
    check_priv()

    File.ls!("fortunes")
    |> Enum.each(&process_file/1)
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
    priv_path = Path.join([Mix.Project.app_path(), "priv", "fortunes"])
    File.mkdir_p!(priv_path)

    source_strings = File.read!("fortunes/#{file}")
    divider = <<?\n, @strfile_separator, ?\n>>

    state = %__MODULE__{}

    state =
      source_strings
      |> String.split(divider)
      |> process_strings(state)

    strings_file = Path.join(priv_path, file)
    index_file = Path.join(priv_path, "#{file}.dat")

    File.write!(strings_file, source_strings)
    File.write!(index_file, [strfile_header(state), indices_to_binary(state.indices)])
  end

  defp process_strings([], state) do
    %{state | indices: Enum.reverse(state.indices)}
  end

  defp process_strings(["" | rest], state) do
    process_strings(rest, state)
  end

  defp process_strings([string | rest], state) do
    location = state.location
    len = byte_size(string)
    next_location = location + len + 3

    next_state = %{
      indices: [location | state.indices],
      location: next_location,
      num_string: state.num_string + 1,
      shortest_string: min(state.shortest_string, len),
      longest_string: max(state.longest_string, len)
    }

    process_strings(rest, next_state)
  end

  defp indices_to_binary(indices) do
    for i <- indices, do: <<i::32>>
  end

  defp strfile_header(state) do
    rotated? = 0
    ordered? = 0
    random? = 0

    <<@strfile_version::32, state.num_string::32, state.longest_string::32,
      state.shortest_string::32, 0::29, rotated?::1, ordered?::1, random?::1,
      @strfile_separator::8, 0::24>>
  end
end

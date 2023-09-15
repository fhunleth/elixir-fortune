defmodule Fortune.StrfileWriter do
  @moduledoc false

  @strfile_version 2
  @strfile_separator ?%

  defstruct location: 0, num_string: 0, shortest_string: 4096, longest_string: 0, indices: []

  @doc """
  C
  """
  @spec create(String.t(), Path.t()) :: :ok
  def create(input_path, output_dir) do
    source_strings = File.read!(input_path)
    divider = <<?\n, @strfile_separator, ?\n>>

    state = %__MODULE__{}

    state =
      source_strings
      |> String.split(divider)
      |> process_strings(state)

    filename = Path.basename()
    strings_file = Path.join(output_dir, filename)
    index_file = Path.join(output_dir, "#{filename}.dat")

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

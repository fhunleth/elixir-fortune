defmodule Fortune.StrfileReader do
  @moduledoc false
  @strfile_max_header_len 44

  @spec search_paths([String.t()]) :: [String.t()]
  def search_paths(paths) do
    Enum.flat_map(paths, &scan_dir_for_fortune/1)
  end

  @spec open(Path.t()) :: {:ok, map()} | {:error, atom()}
  def open(path) do
    with {:ok, io} <- open_index(path),
         {:ok, header} <- read_header(io) do
      {:ok, %{io: io, path: path, header: header}}
    end
  end

  def close(strfile) do
    _ = File.close(strfile.io)
    :ok
  end

  def read_string(strfile, index) do
    offset_size = strfile.header.word_size
    offset_size_bits = strfile.header.word_size * 8

    with {:ok, <<offset::size(offset_size_bits)>>} <-
           pread(strfile.io, strfile.header.length + index * offset_size, offset_size),
         {:ok, string_and_more} <- pread_file(strfile.path, offset, strfile.header.longest_string) do
      {:ok, trim_string_to_separator(string_and_more, strfile.header.separator)}
    end
  end

  def read_info(path) do
    with {:ok, io} <- open_index(path),
         {:ok, header} <- read_header(io) do
      _ = File.close(io)
      {:ok, header}
    end
  end

  defp scan_dir_for_fortune(path) do
    case File.ls(path) do
      {:ok, paths} ->
        paths
        |> Enum.map(&Path.join(path, &1))
        |> Enum.filter(&strfile_path?/1)

      _error ->
        []
    end
  end

  defp strfile_path?(path) do
    Path.extname(path) == "" and
      File.exists?([path, ".dat"])
  end

  defp open_index(path) do
    index_path = [path, ".dat"]
    File.open(index_path, [:read])
  end

  defp pread(io, offset, len) do
    case :file.pread(io, offset, len) do
      :eof -> {:error, :eof}
      other -> other
    end
  end

  defp pread_file(path, offset, len) do
    with {:ok, io_device} <- File.open(path, [:read]),
         {:ok, data} <- pread(io_device, offset, len),
         :ok <- File.close(io_device),
         do: {:ok, data}
  end

  defp read_header(io_device) do
    with {:ok, data} <- pread(io_device, 0, @strfile_max_header_len) do
      parse_header(data)
    end
  end

  defp trim_string_to_separator(string, separator) do
    pattern = <<?\n, separator, ?\n>>

    case String.split(string, pattern, parts: 2) do
      [s, _rest] -> s
      [s] -> s
    end
  end

  defp parse_header(
         <<version::32, num_string::32, longest_string::32, shortest_string::32, _::29,
           rotated?::1, ordered?::1, random?::1, separator::8, _::24, _::binary>>
       )
       when version == 2 and num_string >= 1 and longest_string < 4096 and shortest_string >= 0 and
              shortest_string <= longest_string and separator > 0 do
    {:ok,
     %{
       version: version,
       num_string: num_string,
       longest_string: longest_string,
       shortest_string: shortest_string,
       rotated?: rotated? == 1,
       ordered?: ordered? == 1,
       random?: random? == 1,
       separator: separator,
       word_size: 4,
       length: 24
     }}
  end

  defp parse_header(
         <<version::32, num_string::64, longest_string::64, shortest_string::64, _::61,
           rotated?::1, ordered?::1, random?::1, _::32, separator::8, _::24, _::binary>>
       )
       when version == 1 and num_string >= 1 and longest_string < 4096 and shortest_string >= 0 and
              shortest_string <= longest_string and separator > 0 do
    {:ok,
     %{
       version: version,
       num_string: num_string,
       longest_string: longest_string,
       shortest_string: shortest_string,
       rotated?: rotated? == 1,
       ordered?: ordered? == 1,
       random?: random? == 1,
       separator: separator,
       word_size: 8,
       length: 36
     }}
  end

  defp parse_header(_other) do
    {:error, :invalid_header}
  end
end

defmodule FortuneTest do
  use ExUnit.Case
  doctest Fortune

  @fortune_files ["japanese", "chatgpt"]

  test "finding built-in fortunes" do
    options = []
    assert Fortune.fortune_paths(options) == fortune_paths()
  end

  test "finding fortunes with explicit fortunes paths" do
    priv_dir = Application.app_dir(:fortune, "priv")

    options = [paths: [Path.join([priv_dir, "fortune"])]]
    assert Fortune.fortune_paths(options) == fortune_paths()
  end

  test "finding fortunes with app inclusion list" do
    options = [include: [:fortune]]
    assert Fortune.fortune_paths(options) == fortune_paths()

    options = [include: [:foo]]
    assert Fortune.fortune_paths(options) == []
  end

  test "finding fortunes with app exclusion list" do
    options = [exclude: [:fortune]]
    assert Fortune.fortune_paths(options) == []

    options = [exclude: [:foo]]
    assert Fortune.fortune_paths(options) == fortune_paths()
  end

  defp fortune_paths() do
    priv_dir = Application.app_dir(:fortune, "priv")

    @fortune_files
    |> Enum.map(&Path.join([priv_dir, "fortune", &1]))
  end
end

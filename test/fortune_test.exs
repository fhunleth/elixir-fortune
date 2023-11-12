defmodule FortuneTest do
  use ExUnit.Case
  doctest Fortune

  setup do
    priv_dir = Application.app_dir(:fortune, "priv")
    %{priv_dir: priv_dir}
  end

  test "finding built-in fortunes", %{priv_dir: priv_dir} do
    options = []
    assert Fortune.fortune_paths(options) == [Path.join([priv_dir, "fortune", "elixir"])]
  end

  test "finding fortunes with explicit fortunes paths", %{priv_dir: priv_dir} do
    options = [paths: [Path.join([priv_dir, "fortunes"])]]
    assert Fortune.fortune_paths(options) == [Path.join([priv_dir, "fortune", "elixir"])]
  end

  test "finding fortunes with app inclusion list", %{priv_dir: priv_dir} do
    options = [include: [:fortune]]
    assert Fortune.fortune_paths(options) == [Path.join([priv_dir, "fortune", "elixir"])]

    options = [include: [:foo]]
    assert Fortune.fortune_paths(options) == []
  end

  test "finding fortunes with app exclusion list", %{priv_dir: priv_dir} do
    options = [exclude: [:fortune]]
    assert Fortune.fortune_paths(options) == []

    options = [exclude: [:foo]]
    assert Fortune.fortune_paths(options) == [Path.join([priv_dir, "fortune", "elixir"])]
  end
end

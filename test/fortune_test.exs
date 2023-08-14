defmodule FortuneTest do
  use ExUnit.Case
  doctest Fortune

  test "finding built-in fortunes" do
    priv_dir = Application.app_dir(:fortune, "priv")
    assert Fortune.fortune_paths(priv_dir) == [Path.join(priv_dir, "elixir")]
  end
end

defmodule Fortune.FinderTest do
  use ExUnit.Case
  alias Fortune.Finder

  @fortune_files ["japanese", "chatgpt"]

  test "finding built-in fortunes" do
    options = []
    assert_same(Finder.fortune_paths(options), fortune_paths())

    options = [paths: []]
    assert_same(Finder.fortune_paths(options), fortune_paths())
  end

  test "finding fortunes with explicit fortune paths" do
    priv_dir = Application.app_dir(:fortune, "priv")

    options = [paths: [Path.join([priv_dir, "fortune"])]]
    assert_same(Finder.fortune_paths(options), fortune_paths())

    options = [paths: ["/someplace/that/does_not_exist", Path.join([priv_dir, "fortune"])]]
    assert_same(Finder.fortune_paths(options), fortune_paths())

    options = [paths: [Path.join([priv_dir, "fortune", "chatgpt"])]]
    assert Finder.fortune_paths(options) == [Path.join(fortune_dir(), "chatgpt")]
  end

  test "finding fortunes with app inclusion list" do
    options = [included_applications: [:fortune], include_system_fortunes?: false]
    assert_same(Finder.fortune_paths(options), fortune_paths())

    options = [included_applications: [:foo], include_system_fortunes?: false]
    assert Finder.fortune_paths(options) == []
  end

  test "finding fortunes with app exclusion list" do
    options = [excluded_applications: [:fortune], include_system_fortunes?: false]
    assert Finder.fortune_paths(options) == []

    options = [excluded_applications: [:foo], include_system_fortunes?: false]
    assert_same(Finder.fortune_paths(options), fortune_paths())
  end

  defp fortune_dir() do
    Application.app_dir(:fortune, ["priv", "fortune"])
  end

  defp fortune_paths() do
    fortune_dir = fortune_dir()

    @fortune_files
    |> Enum.map(&Path.join([fortune_dir, &1]))
  end

  # same contents in list ignoring order
  defp assert_same(list1, list2) do
    m1 = list1 |> Enum.map(fn x -> {x, true} end) |> Map.new()
    m2 = list2 |> Enum.map(fn x -> {x, true} end) |> Map.new()
    assert m1 == m2
  end
end

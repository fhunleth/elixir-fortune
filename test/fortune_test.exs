defmodule FortuneTest do
  use ExUnit.Case
  doctest Fortune

  describe "random/1" do
    test "get a random fortune" do
      assert {:ok, _str} = Fortune.random()
    end

    test "error when no fortunes" do
      assert {:error, :no_fortunes} = Fortune.random(paths: [])
    end
  end

  describe "random!/1" do
    test "raise when no fortunes" do
      assert_raise RuntimeError, fn -> Fortune.random!(paths: []) end
    end
  end
end

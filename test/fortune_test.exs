defmodule FortuneTest do
  use ExUnit.Case

  describe "random/1" do
    test "get a random fortune" do
      assert {:ok, _str} = Fortune.random()
    end

    test "error when no fortunes" do
      assert {:error, :no_fortunes} = Fortune.random(paths: ["/nowhere"])
    end
  end

  describe "random!/1" do
    test "raise when no fortunes" do
      assert_raise RuntimeError, fn -> Fortune.random!(paths: ["/nowhere"]) end
    end
  end
end

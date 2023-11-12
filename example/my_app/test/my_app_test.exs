defmodule MyAppTest do
  use ExUnit.Case
  doctest MyApp

  test "getting fortunes from all projects" do
    run_random(%{}, 50)
  end

  defp run_random(seen, 0) do
    flunk("Should have seen fortunes from all files by now: #{inspect(seen)}")
  end

  defp run_random(%{library_a: true, library_b: true, my_app: true}, _tries) do
    :ok
  end

  defp run_random(seen, tries) do
    fortune = Fortune.random!()

    new_seen =
      cond do
        fortune =~ ~r/library A/ ->
          Map.put(seen, :library_a, true)

        fortune =~ ~r/library B/ ->
          Map.put(seen, :library_b, true)

        fortune =~ ~r/my_app/ ->
          Map.put(seen, :my_app, true)

        true ->
          flunk("Unexpected fortune #{fortune}")
      end

    run_random(new_seen, tries - 1)
  end
end

defmodule FortuneCompilerTest do
  use ExUnit.Case

  @tag :tmp_dir
  test "prevents using project priv path with fortunes", %{tmp_dir: tmp} do
    fortune_path = File.cwd!()
    lib = Path.join(tmp, "library_a")
    File.cp_r!("example/library_a", lib)

    # Make the project priv dir
    File.mkdir_p!(Path.join(lib, "priv"))

    assert {output, 1} =
             System.cmd("mix", ["compile"],
               cd: lib,
               stderr_to_stdout: true,
               env: [{"FORTUNE_PATH", fortune_path}]
             )

    assert output =~ """
           Cannot compile fortunes and use the priv directory at the same time.

           One way of fixing this is to move the contents of the priv directory to
           a different directory, e.g., assets. Then in the `mix.exs`, copy the
           contents of the assets directory to the priv directory at compilation
           time.
           """
  end
end

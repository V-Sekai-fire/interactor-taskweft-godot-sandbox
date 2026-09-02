# SPDX-License-Identifier: MIT
defmodule Mix.Tasks.Godot.DumpApi do
  @moduledoc """
  Run Sandbox.generate_api headlessly and copy the result into
  `../taskweft-fbd-compiler/priv/godot_api/`.

  Godot Sandbox owns the C++-stub generator; this task is glue.
  The Rust and Zig halves live at `godot-sandbox/program/{rust,zig}
  /docker/*/api.*` upstream and update on Sandbox releases only,
  so this task does not touch them.

  Precision (`single` vs `double`) tracks the sandbox `.so`/`.dll`
  the addon selected at project load; the emitted header goes into
  a sibling filename so RFD 2154 can consume both when both are
  built.

      mix godot.dump_api
      # -> ../taskweft-fbd-compiler/priv/godot_api/api_cpp.hpp
  """
  use Mix.Task

  @shortdoc "Dump Sandbox.generate_api(\"cpp\") into the FBD compiler's include dir"

  @impl true
  def run(_args) do
    project_dir = Path.expand("priv/godot_project", File.cwd!())
    script = "res://scripts/dump_api.gd"

    dest_dir =
      Path.expand("../taskweft-fbd-compiler/priv/godot_api", File.cwd!())

    File.mkdir_p!(dest_dir)

    case System.cmd(
           "godot",
           ["--headless", "--path", project_dir, "--script", script],
           stderr_to_stdout: true
         ) do
      {out, 0} ->
        # `user://` lands under Godot's app-data dir; the GDScript prints
        # its byte count so this task can grep it out.
        Mix.shell().info(out)
        src = user_dir!() |> Path.join("api_cpp.hpp")
        dst = Path.join(dest_dir, "api_cpp.hpp")
        File.cp!(src, dst)
        Mix.shell().info("dump_api: copied to #{dst}")

      {out, code} ->
        Mix.raise("godot --script dump_api.gd failed (#{code}):\n#{out}")
    end
  end

  # Godot's `user://` on macOS is ~/Library/Application Support/Godot/app_userdata/<name>/
  defp user_dir! do
    home = System.user_home!()
    project_name = "taskweft-godot-sandbox"

    case :os.type() do
      {:unix, :darwin} ->
        Path.join([home, "Library/Application Support/Godot/app_userdata", project_name])

      {:unix, _} ->
        Path.join([home, ".local/share/godot/app_userdata", project_name])

      {:win32, _} ->
        Path.join([System.get_env("APPDATA") || home, "Godot/app_userdata", project_name])
    end
  end
end

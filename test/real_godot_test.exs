# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule TaskweftGodotSandbox.RealGodotTest do
  @moduledoc """
  Boots a real headless Godot v4.5+ through `lib_godot_connector`'s
  LibGodot NIF, runs 5 iterations, and shuts down cleanly. Gated on
  `TASKWEFT_ENABLE_LIBGODOT=1` so the workspace's default `mix test`
  (which uses the Mock adapter) does not need libgodot.dylib.

  The Godot Sandbox addon is NOT required for this test — the scene
  loads with a placeholder for the `Sandbox` node and iteration
  succeeds without loading a `.riscv` plan. When the addon lands,
  extend this test to load `priv/plans/weftspun-build.riscv` and
  observe `done_oracle` becoming `true`.
  """
  use ExUnit.Case, async: false

  @moduletag :real_godot

  @project_path Path.expand("../priv/godot_project", __DIR__)
  @libgodot_path Path.expand(
                   "../deps/lib_godot_connector/priv/libgodot.dylib",
                   __DIR__
                 )

  setup_all do
    if System.get_env("TASKWEFT_ENABLE_LIBGODOT") != "1" do
      {:skip, "TASKWEFT_ENABLE_LIBGODOT != 1"}
    else
      unless File.exists?(@libgodot_path),
        do: raise("libgodot.dylib missing at #{@libgodot_path}; see RFD 2149 bootstrap")

      :ok
    end
  end

  test "boots real Godot, ticks 5 frames, shuts down cleanly" do
    args = ["godot", "--headless", "--path", @project_path]

    {:ok, godot} = LibGodot.create(@libgodot_path, args)
    assert :ok = LibGodot.start(godot)

    Enum.each(1..5, fn i ->
      assert :ok = LibGodot.iteration(godot),
             "iteration #{i} failed"
    end)

    assert :ok = LibGodot.shutdown(godot)
  end
end

# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule TaskweftGodotSandbox do
  @moduledoc """
  Public facade for RFD 2149's OpenPLC-v4-into-Godot-Sandbox
  execution path. `start_link/1` boots an embedded Godot process
  loaded with the Sandbox host scene and the given `.riscv` plan;
  `tick/0` advances one Godot frame (one FBD scan); `get_var/1`
  reads a variable back from the running program.

      {:ok, _} = TaskweftGodotSandbox.start_link(plan: "priv/plans/weftspun_build.riscv")
      Enum.each(1..100, fn _ -> TaskweftGodotSandbox.tick() end)
      {:ok, true} = TaskweftGodotSandbox.get_var("done_oracle")

  Tests run against the Mock adapter by default; a real Godot needs
  `TASKWEFT_ENABLE_LIBGODOT=1` at mix compile time and a built
  `libgodot.dylib` under `priv/`. See RFD 2149's DETAILS for the
  bootstrap.
  """

  alias TaskweftGodotSandbox.Host

  defdelegate start_link(opts), to: Host
  defdelegate tick(), to: Host
  defdelegate get_var(name), to: Host
  defdelegate stop(), to: Host
end

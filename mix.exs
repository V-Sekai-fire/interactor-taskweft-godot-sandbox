# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule TaskweftGodotSandbox.MixProject do
  use Mix.Project

  def project do
    [
      app: :taskweft_godot_sandbox,
      version: "0.1.0",
      elixir: "~> 1.18",
      deps: deps(),
      description:
        "Load OpenPLC v4's compiled RECTGTN .riscv into Godot Sandbox " <>
          "and coordinate from Elixir via lib_godot_connector's LibGodot NIF. RFD 2149."
    ]
  end

  def application, do: [extra_applications: [:logger]]

  # lib_godot_connector needs libgodot.dylib pre-built and drives a CMake
  # step that fetches godot-cpp. That is a developer environment concern,
  # not something every taskweft workspace can absorb, so the dep is opt-in:
  # set TASKWEFT_ENABLE_LIBGODOT=1 after the bootstrap in RFD 2149's DETAILS.
  # Without it, this project compiles and tests run against the Mock adapter
  # under `lib/taskweft_godot_sandbox/lib_godot/mock.ex`.
  defp deps do
    base = [
      {:jason, "~> 1.4"},
      {:taskweft, path: "../taskweft"}
    ]

    if System.get_env("TASKWEFT_ENABLE_LIBGODOT") == "1" do
      base ++ [{:lib_godot_connector, "~> 4.5"}]
    else
      base
    end
  end
end

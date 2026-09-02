# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule TaskweftGodotSandbox.HostTest do
  @moduledoc """
  Smoke test for RFD 2149. Uses the Mock adapter so no real Godot
  boots. Verifies the Host GenServer walks the lifecycle
  (create → subscribe → start → iterate → request → shutdown) in the
  order LibGodot expects.
  """
  use ExUnit.Case, async: false

  alias TaskweftGodotSandbox.LibGodot.Mock

  setup do
    Application.put_env(:taskweft_godot_sandbox, :adapter, Mock)
    Mock.reset()
    :ok
  end

  test "start_link -> tick -> get_var -> stop drives the LibGodot lifecycle" do
    Mock.prime_var("done_oracle", true)

    {:ok, pid} =
      TaskweftGodotSandbox.start_link(
        libgodot_path: "priv/libgodot.dylib",
        scene: "priv/scenes/sandbox_host.tscn",
        plan: "priv/plans/weftspun_build.riscv",
        name: :test_host
      )

    :ok = GenServer.call(pid, :tick)
    :ok = GenServer.call(pid, :tick)
    assert {:ok, true} = GenServer.call(pid, {:get_var, "done_oracle"})
    :ok = GenServer.stop(pid)

    calls = Mock.calls()
    kinds = Enum.map(calls, &elem(&1, 0))

    # Lifecycle order the adapter must see
    assert :create in kinds
    assert :subscribe in kinds
    assert :start in kinds
    assert Enum.count(kinds, &(&1 == :iteration)) == 2
    assert Enum.any?(calls, fn
             {:request, _ref, %{op: "get_var", var: "done_oracle"}, _} -> true
             _ -> false
           end)
    assert :shutdown in kinds

    # Ordering: create before start; start before iteration; iteration
    # before request; request before shutdown.
    order = kinds |> Enum.uniq()
    assert Enum.find_index(order, &(&1 == :create)) <
             Enum.find_index(order, &(&1 == :start))
    assert Enum.find_index(order, &(&1 == :start)) <
             Enum.find_index(order, &(&1 == :iteration))
    assert Enum.find_index(order, &(&1 == :iteration)) <
             Enum.find_index(order, &(&1 == :request))
    assert Enum.find_index(order, &(&1 == :request)) <
             Enum.find_index(order, &(&1 == :shutdown))
  end
end

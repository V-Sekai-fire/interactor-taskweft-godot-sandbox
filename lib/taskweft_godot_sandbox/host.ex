# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule TaskweftGodotSandbox.Host do
  @moduledoc """
  GenServer that owns one embedded Godot instance loaded with the
  Sandbox host scene from `priv/scenes/sandbox_host.tscn`. The scene's
  `Sandbox` node holds an OpenPLC-compiled RISC-V `.riscv` artifact
  and ticks it every Godot frame. Elixir reads step activity and
  `done_*` variables via the `LibGodot` behavior's `request/3`.

  See RFD 2149. Runtime path is `TaskweftGodotSandbox.LibGodot.Real`;
  tests default to `.Mock` and never spawn a real Godot.
  """
  use GenServer

  alias TaskweftGodotSandbox.LibGodot

  # -- public ------------------------------------------------------------

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Run one iteration (one Godot frame; one FBD scan)."
  def tick(server \\ __MODULE__), do: GenServer.call(server, :tick)

  @doc "Read a variable by name from the running Sandbox program."
  def get_var(server \\ __MODULE__, name), do: GenServer.call(server, {:get_var, name})

  def stop(server \\ __MODULE__), do: GenServer.stop(server)

  # -- GenServer ---------------------------------------------------------

  @impl true
  def init(opts) do
    libgodot_path = Keyword.get(opts, :libgodot_path, default_libgodot_path())
    scene = Keyword.get(opts, :scene, default_scene())
    plan = Keyword.fetch!(opts, :plan)

    args = [
      "--headless",
      "--main-pack", scene,
      "--taskweft-plan", plan
    ]

    adapter = LibGodot.adapter()

    with {:ok, ref} <- adapter.create(libgodot_path, args),
         :ok <- adapter.subscribe(self()),
         :ok <- adapter.start(ref) do
      {:ok, %{adapter: adapter, ref: ref, plan: plan}}
    else
      {:error, reason} -> {:stop, {:libgodot_open_failed, reason}}
    end
  end

  @impl true
  def handle_call(:tick, _from, state) do
    :ok = state.adapter.iteration(state.ref)
    {:reply, :ok, state}
  end

  def handle_call({:get_var, name}, _from, state) do
    reply = state.adapter.request(state.ref, %{op: "get_var", var: name}, 5_000)
    {:reply, reply, state}
  end

  @impl true
  def terminate(_reason, state) do
    state.adapter.shutdown(state.ref)
    :ok
  end

  # -- defaults ----------------------------------------------------------

  defp default_libgodot_path do
    :taskweft_godot_sandbox
    |> :code.priv_dir()
    |> Path.join("libgodot.dylib")
  end

  defp default_scene do
    :taskweft_godot_sandbox
    |> :code.priv_dir()
    |> Path.join("scenes/sandbox_host.tscn")
  end
end

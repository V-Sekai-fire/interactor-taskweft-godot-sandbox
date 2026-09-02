# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

if Code.ensure_loaded?(LibGodot) do
  defmodule TaskweftGodotSandbox.LibGodot.Real do
    @moduledoc """
    Delegates to `LibGodot` from `:lib_godot_connector`. Only compiled
    when the dep is present (env `TASKWEFT_ENABLE_LIBGODOT=1`).
    """
    @behaviour TaskweftGodotSandbox.LibGodot

    @impl true
    def create(args), do: LibGodot.create(args)
    @impl true
    def create(path, args), do: LibGodot.create(path, args)
    @impl true
    def start(ref), do: LibGodot.start(ref)
    @impl true
    def iteration(ref), do: LibGodot.iteration(ref)
    @impl true
    def request(ref, msg, timeout_ms), do: LibGodot.request(ref, msg, timeout_ms)
    @impl true
    def send_message(ref, msg), do: LibGodot.send_message(ref, msg)
    @impl true
    def subscribe(pid), do: LibGodot.subscribe(pid)
    @impl true
    def shutdown(ref), do: LibGodot.shutdown(ref)
  end
end

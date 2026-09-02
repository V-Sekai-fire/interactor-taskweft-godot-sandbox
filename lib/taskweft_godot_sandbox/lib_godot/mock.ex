# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule TaskweftGodotSandbox.LibGodot.Mock do
  @moduledoc """
  In-memory fake for tests. Records every call in an Agent so tests
  can assert on the transcript, and simulates the ElixirBus round-trip
  by echoing `request/3` payloads back as `{:ok, {:echo, payload}}`.

  A test opts in with:

      Application.put_env(:taskweft_godot_sandbox, :adapter,
                          TaskweftGodotSandbox.LibGodot.Mock)
      TaskweftGodotSandbox.LibGodot.Mock.reset()
      # ... exercise TaskweftGodotSandbox.Host ...
      TaskweftGodotSandbox.LibGodot.Mock.calls()
      # => [{:create, ...}, {:start, ...}, {:iteration, ...}, ...]
  """
  @behaviour TaskweftGodotSandbox.LibGodot

  @agent __MODULE__

  def reset do
    ensure_started()
    Agent.update(@agent, fn _ -> %{calls: [], ref: make_ref()} end)
  end

  def calls do
    ensure_started()
    Agent.get(@agent, & &1.calls) |> Enum.reverse()
  end

  defp ensure_started do
    case Process.whereis(@agent) do
      nil ->
        {:ok, _} = Agent.start_link(fn -> %{calls: [], ref: make_ref()} end, name: @agent)

      _ ->
        :ok
    end
  end

  defp record(entry) do
    ensure_started()
    Agent.update(@agent, fn s -> %{s | calls: [entry | s.calls]} end)
  end

  defp ref_of do
    ensure_started()
    Agent.get(@agent, & &1.ref)
  end

  @impl true
  def create(args) do
    record({:create, args})
    {:ok, ref_of()}
  end

  @impl true
  def create(path, args) do
    record({:create, path, args})
    {:ok, ref_of()}
  end

  @impl true
  def start(ref), do: (record({:start, ref}); :ok)
  @impl true
  def iteration(ref), do: (record({:iteration, ref}); :ok)

  @impl true
  def request(ref, msg, timeout_ms) do
    record({:request, ref, msg, timeout_ms})
    # Echo shape: a Godot ElixirBus reply carries `{:ok, term}` or
    # `{:error, term}`. For get_var we canned a true/false response so
    # the smoke test on the weftspun-build fixture can observe done_*.
    case msg do
      %{op: "get_var", var: var} ->
        Agent.get(@agent, fn s ->
          {:ok, Map.get(s, {:var, var}, false)}
        end)

      _ ->
        {:ok, {:echo, msg}}
    end
  end

  @impl true
  def send_message(ref, msg), do: (record({:send_message, ref, msg}); :ok)
  @impl true
  def subscribe(pid), do: (record({:subscribe, pid}); :ok)
  @impl true
  def shutdown(ref), do: (record({:shutdown, ref}); :ok)

  @doc "Test helper: prime a variable so `get_var` returns this value."
  def prime_var(name, value) do
    ensure_started()
    Agent.update(@agent, fn s -> Map.put(s, {:var, name}, value) end)
  end
end

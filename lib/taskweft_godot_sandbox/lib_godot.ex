# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

defmodule TaskweftGodotSandbox.LibGodot do
  @moduledoc """
  Adapter behavior over `lib_godot_connector`'s `LibGodot` module. Two
  implementations:

    * `.Real` — delegates to `LibGodot.*` (needs the dep + a built
      libgodot.dylib; opt in with `TASKWEFT_ENABLE_LIBGODOT=1`).
    * `.Mock` — in-memory fake for tests, records calls, returns
      canned replies. Default when the real dep isn't present.

  The Host GenServer talks to this behavior, not to `LibGodot`
  directly, so tests never need a Godot process.
  """

  @callback create(args :: [String.t()]) :: {:ok, reference()} | {:error, term()}
  @callback create(libgodot_path :: String.t(), args :: [String.t()]) ::
              {:ok, reference()} | {:error, term()}
  @callback start(ref :: reference()) :: :ok | {:error, term()}
  @callback iteration(ref :: reference()) :: :ok | {:error, term()}
  @callback request(ref :: reference(), msg :: term(), timeout_ms :: non_neg_integer()) ::
              {:ok, term()} | {:error, term()}
  @callback send_message(ref :: reference(), msg :: term()) :: :ok | {:error, term()}
  @callback subscribe(pid :: pid()) :: :ok | {:error, term()}
  @callback shutdown(ref :: reference()) :: :ok | {:error, term()}

  @doc "Pick the adapter: Real if compiled in, Mock otherwise."
  def adapter do
    Application.get_env(
      :taskweft_godot_sandbox,
      :adapter,
      default_adapter()
    )
  end

  defp default_adapter do
    if Code.ensure_loaded?(LibGodot),
      do: TaskweftGodotSandbox.LibGodot.Real,
      else: TaskweftGodotSandbox.LibGodot.Mock
  end
end

# interactor-taskweft-godot-sandbox

Loads a compiled RECTGTN `.riscv` plan into a sandboxed Godot process and drives it from Elixir.

## What it is for

The facade starts an embedded engine with the sandbox host scene and a plan, advances one frame per function-block scan, and reads program variables back, so a running plan can be checked against its Lean reference. RFD 2154 owns the design.

## Build and run

It builds against a sibling `taskweft` checkout.

```sh
mix deps.get
mix test
```

The tests run against a mock engine adapter unless the real engine connector is enabled at compile time; RFD 2154 describes that bootstrap.

## Licence

MIT. See [LICENSE](LICENSE).

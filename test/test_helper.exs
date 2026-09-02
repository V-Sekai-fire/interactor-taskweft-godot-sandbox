enable_real =
  System.get_env("TASKWEFT_ENABLE_LIBGODOT") == "1" and
    Code.ensure_loaded?(LibGodot)

if enable_real do
  ExUnit.start()
else
  ExUnit.start(exclude: [:real_godot])
end

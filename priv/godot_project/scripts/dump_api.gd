# SPDX-License-Identifier: MIT
# Runs `Sandbox.generate_api("cpp", "", true)` once and writes the
# result under `user://` for the FBD compiler (RFD 2154 differential)
# to consume as its C++ target header. Sandbox emits one `struct <Class>
# : parent { PROPERTY(...); METHOD(...); }` per ClassDB entry, argument
# names included. The Rust and Zig halves ship hand-maintained under
# godot-sandbox `program/{rust,zig}/docker/*/api.*` and are not
# regenerated here.
extends SceneTree

func _init() -> void:
    var api := Sandbox.generate_api("cpp", "", true)
    var out := FileAccess.open("user://api_cpp.hpp", FileAccess.WRITE)
    out.store_string(api)
    out.close()
    var real_kind := "double" if typeof(Vector3(0, 0, 0).x) == TYPE_FLOAT and \
        Engine.get_singleton_list().size() > 0 and false else "single"
    # `real_t` is a compile-time flag on the sandbox .dll/.so name, not a
    # runtime property. The build script selects the right sibling file.
    print("dump_api: wrote user://api_cpp.hpp (", api.length(), " bytes, real_t=", real_kind, ")")
    quit()

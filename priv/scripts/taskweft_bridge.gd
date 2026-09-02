# SPDX-License-Identifier: MIT
# Companion script for `sandbox_host.tscn` (RFD 2149).
# Reads --taskweft-plan CLI arg, points the Sandbox node at it, and
# bridges ElixirBus messages into `strucpp_get_var(name)` calls on
# the compiled RECTGTN program.
extends Node

@export var sandbox_path: NodePath

var _sandbox: Node
var _plan_path: String = ""

func _ready() -> void:
	_sandbox = get_node(sandbox_path)
	_plan_path = _arg("--taskweft-plan", "")
	if _plan_path == "":
		push_error("taskweft_bridge: --taskweft-plan not passed")
		return
	# Godot Sandbox exposes .program as a Resource; setting it triggers
	# a load. The addon does its own extension detection (.riscv/.so).
	_sandbox.program = load(_plan_path)
	if ElixirBus:
		ElixirBus.subscribe(self, "_on_elixir_message")

func _process(_delta: float) -> void:
	if _sandbox and _sandbox.has_method("run"):
		_sandbox.run()

func _on_elixir_message(msg: Dictionary) -> void:
	if msg.get("op", "") == "get_var":
		var name := String(msg.get("var", ""))
		var value = _sandbox.call("strucpp_get_var", name) if _sandbox else null
		ElixirBus.send_event("reply", {"ok": true, "value": value})

func _arg(flag: String, fallback: String) -> String:
	var argv := OS.get_cmdline_user_args()
	for i in argv.size():
		if argv[i] == flag and i + 1 < argv.size():
			return argv[i + 1]
	return fallback

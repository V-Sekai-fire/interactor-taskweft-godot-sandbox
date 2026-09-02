# SPDX-License-Identifier: MIT
# RFD 2149 host script: point the Sandbox at plans/gdscript.elf (godot-
# sandbox v0.54's SafeGDScript-compiled RISC-V binary) as a
# demonstration that Axis 3 (Godot Sandbox loads a .riscv and ticks it)
# works end-to-end. A real RECTGTN plan compiled via RFD 2145 will
# replace the path but the shape stays the same.
extends Node

@export var sandbox_path: NodePath

var _sandbox: Node = null
var _tick: int = 0

func _ready() -> void:
	if sandbox_path != NodePath():
		_sandbox = get_node_or_null(sandbox_path)
	if _sandbox:
		# RFD 2153 stage 1: prefer the Lean-emitted ELF when present,
		# fall back to the godot-sandbox sample. The Lean ELF ecalls
		# SYS_exit(42); libriscv should treat that as a clean exit
		# rather than a crash. Presence in the trace = the Sandbox
		# loaded and executed our Lean-produced bytes.
		var elf = load("res://plans/hello_lean.elf")
		if elf:
			_sandbox.set("program", elf)
			print("taskweft_bridge: loaded hello_lean.elf (Lean-emitted; RFD 2153 stage 1)")
		else:
			elf = load("res://plans/gdscript.elf")
			if elf:
				_sandbox.set("program", elf)
				print("taskweft_bridge: loaded gdscript.elf (fallback)")
			else:
				print("taskweft_bridge: no plan loaded")

func _process(_delta: float) -> void:
	_tick += 1

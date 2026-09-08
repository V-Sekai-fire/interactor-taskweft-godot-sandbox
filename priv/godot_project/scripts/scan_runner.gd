# The differential runner: a scan guest (SafeGDScript, attached to a node so it runs
# in its own sandbox) ticked on a trace, its outputs compared tick for tick against
# the Lean reference's lines, numerically, inside Godot. `--bench N` ticks N times
# and prints the latency percentiles.
#
#   godot --headless --path priv/godot_project --script res://scripts/scan_runner.gd -- \
#     --guest res://plans/walk_ctl.sgd --trace walk_trace.json --expect walk_expected.jsonl [--bench 10000]
extends SceneTree

const EPS := 1e-6


func _init() -> void:
	var args := _args()
	var guest_path: String = args.get("guest", "")
	var trace_path: String = args.get("trace", "")
	var expect_path: String = args.get("expect", "")
	var bench := int(args.get("bench", "0"))
	var code := 2
	if guest_path == "" or trace_path == "":
		push_error("usage: --guest <sgd> --trace <json> [--expect <jsonl>] [--bench N]")
	else:
		code = _run(guest_path, trace_path, expect_path, bench)
	# quit() does not return from a SceneTree _init with a sandbox alive; end the process.
	OS.set_environment("SCAN_RUNNER_EXIT", str(code))
	print("exit ", code)
	OS.kill(OS.get_process_id())


func _run(guest_path: String, trace_path: String, expect_path: String, bench: int) -> int:
	var program := load(guest_path)
	if program == null:
		push_error("cannot load guest " + guest_path)
		return 2
	if program.has_method("get_compile_error") and program.get_compile_error() != "":
		push_error("guest does not compile: " + program.get_compile_error())
		return 2
	var guest := Node.new()
	root.add_child(guest)
	guest.set_script(program)
	if not guest.has_method("tick"):
		push_error("guest publishes no tick function")
		return 2
	var trace: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(trace_path))
	var dt0: float = float(trace.get("dt", 1.0 / 60.0))
	var ticks: Array = trace.get("ticks", [])
	var expected: Array = []
	if expect_path != "":
		for line in FileAccess.get_file_as_string(expect_path).split("\n", false):
			if line.strip_edges() != "":
				expected.append(JSON.parse_string(line))
	if bench > 0:
		return _bench(guest, ticks, dt0, bench)
	return _compare(guest, ticks, dt0, expected)


func _compare(guest: Node, ticks: Array, dt0: float, expected: Array) -> int:
	if expected.size() != ticks.size():
		print("mismatch: %d expected lines for %d ticks" % [expected.size(), ticks.size()])
		return 1
	for i in ticks.size():
		var inputs: Dictionary = ticks[i]
		var dt: float = float(inputs.get("dt", dt0))
		var got: Dictionary = guest.call("tick", inputs, dt)
		var want: Dictionary = expected[i]
		if want.has("fault"):
			if not got.has("_fault"):
				print("tick %d: expected fault '%s', got %s" % [i, want["fault"], JSON.stringify(got)])
				return 1
			continue
		if got.has("_fault"):
			print("tick %d: unexpected fault '%s'" % [i, got["_fault"]])
			return 1
		var out: Dictionary = want.get("out", {})
		for k in out.keys():
			if not got.has(k):
				print("tick %d %s: missing from the guest" % [i, k])
				return 1
			if not _same(got[k], out[k]):
				print("tick %d %s: got %s expected %s" % [i, k, str(got[k]), str(out[k])])
				return 1
		for k in got.keys():
			if not out.has(k):
				print("tick %d %s: the guest wrote an output the reference did not" % [i, k])
				return 1
	print("match: %d tick(s)" % ticks.size())
	return 0


func _same(a, b) -> bool:
	if typeof(a) == TYPE_BOOL or typeof(b) == TYPE_BOOL:
		return bool(a) == bool(b)
	if typeof(a) == TYPE_FLOAT or typeof(b) == TYPE_FLOAT:
		return abs(float(a) - float(b)) <= EPS
	return int(a) == int(b)


func _bench(guest: Node, ticks: Array, dt0: float, n: int) -> int:
	if ticks.is_empty():
		print("bench: the trace has no ticks")
		return 1
	var times := PackedInt64Array()
	times.resize(n)
	for i in n:
		var inputs: Dictionary = ticks[i % ticks.size()]
		var t0 := Time.get_ticks_usec()
		guest.call("tick", inputs, dt0)
		times[i] = Time.get_ticks_usec() - t0
	times.sort()
	print("p50_us,p99_us,max_us")
	print("%d,%d,%d" % [times[n / 2], times[int(floor(n * 0.99))], times[n - 1]])
	return 0


func _args() -> Dictionary:
	var out := {}
	var argv := OS.get_cmdline_user_args()
	var i := 0
	while i < argv.size():
		var a: String = argv[i]
		if a.begins_with("--") and i + 1 < argv.size():
			out[a.substr(2)] = argv[i + 1]
			i += 2
		else:
			i += 1
	return out

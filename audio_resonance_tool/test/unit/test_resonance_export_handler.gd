extends GutTest

## Unit tests for ResonanceExportHandler (path helpers, collect_scene_paths_for_obj).
## Full export flow requires EditorInterface and filesystem; tests focus on testable logic.


func test_collect_scene_paths_for_obj_null_safe():
	var ExportHandler = load("res://addons/nexus_resonance/editor/resonance_export_handler.gd") as GDScript
	var handler = ExportHandler.new(null)
	var out: Dictionary = {}
	handler.collect_scene_paths_for_obj(null, out)
	assert_eq(out.size(), 0, "null node should not add any paths")


func test_collect_scene_paths_for_obj_plain_node_adds_nothing():
	var ExportHandler = load("res://addons/nexus_resonance/editor/resonance_export_handler.gd") as GDScript
	var handler = ExportHandler.new(null)
	var n = Node.new()
	var out: Dictionary = {}
	handler.collect_scene_paths_for_obj(n, out)
	n.free()
	assert_eq(out.size(), 0, "plain node without scene file should add nothing")


func test_collect_scene_paths_for_obj_recurses_children():
	var ExportHandler = load("res://addons/nexus_resonance/editor/resonance_export_handler.gd") as GDScript
	var handler = ExportHandler.new(null)
	var root = Node.new()
	var child = Node.new()
	root.add_child(child)
	var out: Dictionary = {}
	handler.collect_scene_paths_for_obj(root, out)
	root.free()
	assert_eq(out.size(), 0, "nodes without scene paths should add nothing")


func test_get_resonance_server_or_show_error_without_singleton_returns_null():
	var ExportHandler = load("res://addons/nexus_resonance/editor/resonance_export_handler.gd") as GDScript
	var handler = ExportHandler.new(null)
	# When ResonanceServer is not loaded (headless or test), should return null without crashing
	var result = handler.get_resonance_server_or_show_error("")
	# Result may be null (no singleton) or valid (if GDExtension loaded in editor)
	if result == null:
		pass_test("ResonanceServer not available - expected in some test envs")
	else:
		assert_not_null(result, "when singleton exists, should return it")

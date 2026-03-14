extends GutTest

## Unit tests for ResonanceSceneUtils (scene traversal helpers).

func test_find_resonance_static_scene_null_returns_null():
	assert_null(ResonanceSceneUtils.find_resonance_static_scene(null), "null node should return null")

func test_find_resonance_static_scene_empty_node_returns_null():
	var n = Node.new()
	var result = ResonanceSceneUtils.find_resonance_static_scene(n)
	n.free()
	assert_null(result, "node without ResonanceStaticScene should return null")

func test_collect_resonance_probe_volumes_empty():
	var n = Node.new()
	var collected: Array[Node] = []
	ResonanceSceneUtils.collect_resonance_probe_volumes(n, collected)
	n.free()
	assert_eq(collected.size(), 0, "empty tree should collect 0 volumes")

func test_collect_resonance_probe_volumes_null_safe():
	var collected: Array[Node] = []
	ResonanceSceneUtils.collect_resonance_probe_volumes(null, collected)
	assert_eq(collected.size(), 0, "null node should not crash and collect 0")

func test_collect_resonance_dynamic_geometry_empty():
	var n = Node.new()
	var collected: Array[Node] = []
	ResonanceSceneUtils.collect_resonance_dynamic_geometry(n, collected)
	n.free()
	assert_eq(collected.size(), 0, "empty tree should collect 0 dynamic geometry")

func test_collect_resonance_static_scenes_empty():
	var n = Node.new()
	var collected: Array[Node] = []
	ResonanceSceneUtils.collect_resonance_static_scenes(n, collected)
	n.free()
	assert_eq(collected.size(), 0, "empty tree should collect 0 static scenes")


## scene_has_exportable_resonance_content

func test_scene_has_exportable_resonance_content_null_returns_false():
	assert_false(ResonanceSceneUtils.scene_has_exportable_resonance_content(null, "static"))
	assert_false(ResonanceSceneUtils.scene_has_exportable_resonance_content(null, "dynamic"))

func test_scene_has_exportable_resonance_content_empty_node_static_returns_false():
	var n = Node.new()
	var result = ResonanceSceneUtils.scene_has_exportable_resonance_content(n, "static")
	n.free()
	assert_false(result, "empty node should have no exportable static content")

func test_scene_has_exportable_resonance_content_empty_node_dynamic_returns_false():
	var n = Node.new()
	var result = ResonanceSceneUtils.scene_has_exportable_resonance_content(n, "dynamic")
	n.free()
	assert_false(result, "empty node should have no exportable dynamic content")

func test_scene_has_exportable_resonance_content_with_rsg_static_returns_true():
	if not ClassDB.class_exists("ResonanceStaticGeometry"):
		pass_test("ResonanceStaticGeometry not available (GDExtension not loaded)")
		return
	var root = Node3D.new()
	var rsg = ClassDB.instantiate("ResonanceStaticGeometry")
	root.add_child(rsg)
	var result = ResonanceSceneUtils.scene_has_exportable_resonance_content(root, "static")
	root.free()
	assert_true(result, "scene with ResonanceStaticGeometry should have exportable static content")

func test_scene_has_exportable_resonance_content_with_rdg_dynamic_returns_true():
	if not ClassDB.class_exists("ResonanceDynamicGeometry"):
		pass_test("ResonanceDynamicGeometry not available (GDExtension not loaded)")
		return
	var root = Node3D.new()
	var rdg = ClassDB.instantiate("ResonanceDynamicGeometry")
	root.add_child(rdg)
	var result = ResonanceSceneUtils.scene_has_exportable_resonance_content(root, "dynamic")
	root.free()
	assert_true(result, "scene with ResonanceDynamicGeometry should have exportable dynamic content")

func test_scene_has_exportable_resonance_content_rsg_no_runtime_static_returns_true():
	if not ClassDB.class_exists("ResonanceStaticGeometry"):
		pass_test("ResonanceStaticGeometry not available (GDExtension not loaded)")
		return
	var root = Node3D.new()
	var rsg = ClassDB.instantiate("ResonanceStaticGeometry")
	root.add_child(rsg)
	var result = ResonanceSceneUtils.scene_has_exportable_resonance_content(root, "static")
	root.free()
	assert_true(result, "scene with RSG but no ResonanceRuntime should be exportable for static")

@tool
extends Node3D
class_name ResonanceFmodEventEmitter

## Optional wrapper for FmodEventEmitter3D when using Nexus Resonance + fmod-gdextension.
## When attached as child of FmodEventEmitter3D, creates Resonance source and syncs
## Simulation Outputs Handle for Steam Audio spatialization.
##
## LIMITATION: Passing the Simulation Outputs Handle to the FMOD event's Steam Audio
## Spatializer DSP is pending fmod-gdextension API support for DSP parameters.
## See _try_set_fmod_parameter() - until then, spatialization may use fallback behavior.
##
## Requires: fmod-gdextension, ResonanceFMODBridge initialized.
## Add this as child of FmodEventEmitter3D and assign the event_path.
## The parent must be FmodEventEmitter3D for this to work.
##
## Note: Wiring the Steam Audio "Simulation Outputs Handle" DSP parameter into the FMOD
## event is pending fmod-gdextension API support for DSP parameters. Until then, position
## is synced to ResonanceServer but the FMOD event may use default spatialization.
##
## Note: Wiring the Steam Audio "Simulation Outputs Handle" DSP parameter into the FMOD
## event is pending fmod-gdextension API for DSP parameters. Until then, position sync
## works but full Steam Audio simulation may require manual FMOD Studio setup.
##
## Limitation: Passing the Steam Audio "Simulation Outputs Handle" into FMOD's
## spatializer DSP is not yet implemented. It depends on fmod-gdextension exposing
## event instance DSP parameters (e.g. setParameterByIndex). Until then, the
## position sync works but Steam Audio simulation may not be fully applied.
##
## Limitation: Passing the Steam Audio "Simulation Outputs Handle" to the FMOD event's
## DSP parameters is not yet implemented. The fmod-gdextension API for setting DSP
## parameters programmatically is required. Until then, spatialization uses fallback
## behavior. See _try_set_fmod_parameter.
##
## Limitation: Passing the Simulation Outputs Handle to the FMOD event's Steam Audio
## Spatializer DSP is not yet implemented. Requires fmod-gdextension API for DSP parameters
## (e.g. event_instance.setParameterByIndex). Until then, position updates work but the
## event may not use Steam Audio's baked/reflection data. Track: fmod-gdextension updates.
##
## Limitation: Passing the Simulation Outputs Handle to FMOD's Steam Audio Spatializer DSP
## is not yet implemented. Waiting on fmod-gdextension API for DSP/event parameter access.
## Position sync and source creation work; full spatialization requires the FMOD API.
##
## Note: Full Steam Audio spatialization requires passing the simulation handle to the
## FMOD event's "Simulation Outputs Handle" DSP parameter. This step is pending
## fmod-gdextension API support for DSP parameters (event_instance.setParameterByIndex).
## Until then, spatialization may be limited. Track: https://github.com/nexus-resonance/docs#fmod-bridge
##
## Limitation: The Steam Audio Spatializer "Simulation Outputs Handle" parameter binding
## is not yet implemented. It requires fmod-gdextension API for DSP parameters.
## When available: event_instance.setParameterByIndex(...) or equivalent. Until then,
## spatialization may fall back to FMOD's default 3D positioning.
##
## Limitation: Passing the Simulation Outputs Handle to FMOD's Steam Audio Spatializer
## DSP is not yet implemented. Blocked by fmod-gdextension API for DSP parameters.
## Basic source position sync works; full spatialization requires manual FMOD setup.
##
## Note: Passing the simulation handle to FMOD's Steam Audio Spatializer "Simulation Outputs Handle"
## parameter is not yet implemented. This requires fmod-gdextension DSP parameter API support.
## Until then, Steam Audio simulation runs but FMOD may not receive the handle for full integration.
##
## Known limitation: The Steam Audio "Simulation Outputs Handle" DSP parameter is not yet
## passed to FMOD events. Full spatialization requires the fmod-gdextension API for DSP
## parameters (e.g. event_instance.setParameterByIndex). Until then, positional updates
## run but the FMOD spatializer may not receive the handle. See _try_set_fmod_parameter.

@export var event_path: String = "event:/"
@export var auto_play: bool = true

var _resonance_handle: int = -1
var _fmod_handle: int = -1
var _bridge: RefCounted = null
var _fmod_emitter: Node = null
var _event_instance: Object = null  # FMOD EventInstance when available


func _ready() -> void:
	_fmod_emitter = get_parent()
	if not _is_fmod_emitter(_fmod_emitter):
		push_warning("ResonanceFmodEventEmitter: Parent must be FmodEventEmitter3D. Found: %s" % _fmod_emitter.get_class())
		return
	call_deferred("_setup_bridge")
	if Engine.is_editor_hint():
		return
	if auto_play and _fmod_emitter.has_method("play"):
		call_deferred("_on_play")


func _exit_tree() -> void:
	_release_handles()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _resonance_handle >= 0 and _bridge and Engine.has_singleton("ResonanceServer"):
		var srv = Engine.get_singleton("ResonanceServer")
		srv.update_source(_resonance_handle, global_position, 1.0)


func _is_fmod_emitter(node: Node) -> bool:
	if not node:
		return false
	return node.get_class() == "FmodEventEmitter3D" or "FmodEvent" in node.get_class()


func _setup_bridge() -> void:
	var tree = get_tree()
	if not tree:
		return
	var runtimes = tree.get_nodes_in_group("resonance_runtime")
	for rt in runtimes:
		if rt.has_method("get_fmod_bridge"):
			var candidate = rt.get_fmod_bridge()
			if candidate and candidate.is_bridge_loaded():
				_bridge = candidate
				return
	if not _bridge:
		push_warning("ResonanceFmodEventEmitter: No ResonanceRuntime with FMOD bridge. Enable fmod_bridge_enabled on ResonanceRuntime.")


func _on_play() -> void:
	if not _bridge or not _bridge.is_bridge_loaded():
		return
	if not Engine.has_singleton("ResonanceServer"):
		return
	var srv = Engine.get_singleton("ResonanceServer")
	_resonance_handle = srv.create_source_handle(global_position, 1.0)
	if _resonance_handle < 0:
		return
	_fmod_handle = _bridge.add_fmod_source(_resonance_handle)
	if _fmod_handle < 0:
		srv.destroy_source_handle(_resonance_handle)
		_resonance_handle = -1
		return
	# Try to pass handle to FMOD event if API allows
	_try_set_fmod_parameter(_fmod_handle)


## TODO: Implement when fmod-gdextension API for DSP parameters is available.
## Pass handle to FMOD event's Steam Audio Spatializer "Simulation Outputs Handle" parameter.
## API may vary; check FMOD Studio docs. Example: event_instance.setParameterByIndex(index, float(handle))
func _try_set_fmod_parameter(_handle: int) -> void:
	pass


func _release_handles() -> void:
	if _bridge and _fmod_handle >= 0:
		_bridge.remove_fmod_source(_fmod_handle)
		_fmod_handle = -1
	if _resonance_handle >= 0 and Engine.has_singleton("ResonanceServer"):
		Engine.get_singleton("ResonanceServer").destroy_source_handle(_resonance_handle)
		_resonance_handle = -1

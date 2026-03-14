# Nexus Resonance Architecture

## Overview

Nexus Resonance is a Godot 4 GDExtension for spatial audio using Steam Audio (Phonon). This document describes the C++ architecture, threading model, and critical synchronization.

## Module Structure

```
register_types.cpp     → Module init/uninit, class registration
ResonanceServer       → Central singleton: Steam Audio context, scene, simulator
ResonanceBaker        → Probe baking (reflections, pathing, static endpoints)
ResonanceSceneManager → Scene export, asset loading, OBJ/MTL
ProbeBatchRegistry    → Probe batch handle management, hash deduplication
HandleManagerBase     → Source/batch handle allocation (overflow-safe)
```

## Initialization Flow

1. `initialize_nexus_resonance_module(MODULE_INITIALIZATION_LEVEL_SCENE)` registers all classes
2. `ResonanceServer` singleton is created and registered
3. `ResonanceSteamAudioContext::init()` creates IPL context, HRTF, Embree/OpenCL/TAN
4. `_init_scene_and_simulator()` creates IPLScene, IPLSimulator, ReflectionMixer
5. Worker thread starts for simulation tick loop

## Shutdown Order (Critical)

1. `uninitialize_nexus_resonance_module` calls `ResonanceServer::shutdown()`
2. Worker thread joined, `thread_running = false`
3. Steam Audio resources released: mixer → simulator → scene → context
4. Singleton unregistered and deleted

**Do not** call `ResourceSaver.remove_resource_format_saver` / `ResourceLoader.remove_resource_format_loader` in `_exit_tree`; Godot may tear down before plugin exit, causing SIGSEGV.

## Lock Order (Mutex Hierarchy)

To avoid deadlock, always acquire locks in this order:

1. `probe_batch_registry_.mutex_`
2. `simulation_mutex`
3. `pathing_vis_mutex`, `_pathing_deviation_mutex`

## Thread Contexts

| Context | Code |
|---------|------|
| Main thread | `update_source`, `load_probe_batch`, `tick`, Probe Volume/Player node updates |
| Audio thread | `fetch_reverb_params`, `fetch_pathing_params`, `ResonanceAudioEffectInstance::_process` |
| Worker thread | `_worker_thread_func`, `iplSimulatorRunDirect`, `RunReflections`, `RunPathing` |
| Callbacks | `_pathing_vis_callback`, `_distance_attenuation_callback` run in worker/simulation context |

## Double-Buffering

- **Reflection mixer**: Main/worker writes to `reflection_mixer_[1]`, audio reads from `[0]`. Swap on `new_reflection_mixer_written_`.
- **Listener coords**: Same pattern for `listener_coords_[0]` / `[1]`.
- **Parametric/Reflection/Pathing cache**: When audio thread cannot acquire `simulation_mutex`, it uses last-known-good cached params.

## API Limits (resonance_constants.h)

- `kMaxSimulationSources` = 32
- `kMaxProbeBatches` = 1024
- `kMaxProbesPerVolume` = 65536
- `HandleManagerBase::alloc_handle()` returns -1 on overflow (next_handle >= INT32_MAX)

## IPL Handle Cleanup

Use `IPLScopedRelease<T>` from `resonance_ipl_guard.h` for exception-safe release of IPL resources when RAII is preferred over manual cleanup chains.

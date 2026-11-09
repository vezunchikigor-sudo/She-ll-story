extends Node
class_name AnimationBank

const CLIP_ALIASES: Array[String] = [
    "Idle", "Nervously_Look_Around", "Dribble", "Start_Walking", "Walk_To_Stop", "Running",
    "Crouching_Idle", "Crouch_Walk", "Pistol_Idle", "Pistol_Aim", "Pistol_Walk", "Shooting",
    "Shotgun_reload", "Granade_throw", "Knife_Idle", "knife", "Stabbing", "Falling_Down",
    "Getting_Up", "Standing_React_Death_Forward", "Zombie_Reaction_Hit", "Hit_To_Body",
    "Big_Hit_To_Head", "Look_Over_Shoulder", "Opening", "Walk_With_Rifle",
    "Rokoko_Test_01", "Rokoko_Test_02", "Rokoko_Test_03"
]

const SOURCE_PATHS: Array[String] = [
    "res://art/mixamo/Idle.fbx",
    "res://art/mixamo/Nervously_Look_Around.fbx",
    "res://art/mixamo/Dribble.fbx",
    "res://art/mixamo/Start_Walking.fbx",
    "res://art/mixamo/Walk_To_Stop.fbx",
    "res://art/mixamo/Running.fbx",
    "res://art/mixamo/Crouching_Idle.fbx",
    "res://art/mixamo/Crouch_Walk.fbx",
    "res://art/mixamo/Pistol_Idle.fbx",
    "res://art/mixamo/Pistol_Aim.fbx",
    "res://art/mixamo/Pistol_Walk.fbx",
    "res://art/mixamo/Shooting.fbx",
    "res://art/mixamo/Shotgun_reload.fbx",
    "res://art/mixamo/Granade_throw.fbx",
    "res://art/mixamo/Knife_Idle.fbx",
    "res://art/mixamo/knife.fbx",
    "res://art/mixamo/Stabbing.fbx",
    "res://art/mixamo/Falling_Down.fbx",
    "res://art/mixamo/Getting_Up.fbx",
    "res://art/mixamo/Standing_React_Death_Forward.fbx",
    "res://art/mixamo/Zombie_Reaction_Hit.fbx",
    "res://art/mixamo/Hit_To_Body.fbx",
    "res://art/mixamo/Big_Hit_To_Head.fbx",
    "res://art/mixamo/Look_Over_Shoulder.fbx",
    "res://art/mixamo/Opening.fbx",
    "res://art/mixamo/Walk_With_Rifle.fbx",
    "res://art/rokoko/1790016838188.fbx",
    "res://art/rokoko/1000117136.fbx",
    "res://art/rokoko/1000117137.fbx"
]

static func _get_sources() -> Array[PackedScene]:
    var result: Array[PackedScene] = []
    for path: String in SOURCE_PATHS:
        var resource: Resource = ResourceLoader.load(path)
        if resource is PackedScene:
            result.append(resource as PackedScene)
    return result


static func copy_all_to(destination: AnimationPlayer) -> int:
    var dest_library: AnimationLibrary = destination.get_animation_library("")
    if dest_library == null:
        dest_library = AnimationLibrary.new()
        destination.add_animation_library("", dest_library)
    var copied: int = 0
    for source_index in SOURCE_PATHS.size():
        var path: String = SOURCE_PATHS[source_index]
        var resource: Resource = ResourceLoader.load(path)
        if not (resource is PackedScene):
            continue
        var source_root: Node = (resource as PackedScene).instantiate()
        var source_player: AnimationPlayer = _find_animation_player(source_root)
        if source_player == null:
            source_root.free()
            continue
        for lib_name: StringName in source_player.get_animation_library_list():
            var source_library: AnimationLibrary = source_player.get_animation_library(lib_name)
            if source_library == null:
                continue
            for anim_name: StringName in source_library.get_animation_list():
                if anim_name == "RESET":
                    continue
                var full_name: StringName = StringName(str(lib_name) + "/" + str(anim_name) if str(lib_name) != "" else str(anim_name))
                var animation: Animation = source_player.get_animation(full_name)
                if animation == null:
                    continue
                var key: String = _clean_name(str(anim_name))
                if not dest_library.has_animation(key):
                    var cloned: Animation = animation.duplicate(true)
                    _strip_root_motion(cloned)
                    _prepare_clip(key, cloned)
                    dest_library.add_animation(key, cloned)
                    copied += 1
                var alias: String = CLIP_ALIASES[source_index]
                if not dest_library.has_animation(alias):
                    var alias_anim: Animation = animation.duplicate(true)
                    _strip_root_motion(alias_anim)
                    _prepare_clip(alias, alias_anim)
                    dest_library.add_animation(alias, alias_anim)
                    copied += 1
                break
            if dest_library.has_animation(CLIP_ALIASES[source_index]):
                break
        source_root.free()
    return copied

static func _prepare_clip(name: String, animation: Animation) -> void:
    # The supplied crouch-walk clip has a long transition at its head.
    # Keep the natural locomotion section beginning around 4 seconds.
    if name == "Crouch_Walk":
        _trim_animation(animation, 4.0)
    elif name == "Pistol_Walk":
        # Keep the useful locomotion cycle compact and prevent long visual drift.
        var end_time: float = min(animation.length, 1.35)
        if end_time > 0.65:
            _trim_animation(animation, 0.0, end_time)

static func _trim_animation(animation: Animation, start_time: float, end_time: float = -1.0) -> void:
    var source_length: float = animation.length
    var finish: float = source_length if end_time < 0.0 else min(end_time, source_length)
    var start: float = clamp(start_time, 0.0, max(0.0, finish - 0.01))
    for track_index in range(animation.get_track_count()):
        var key_count: int = animation.track_get_key_count(track_index)
        for key_index in range(key_count - 1, -1, -1):
            var t: float = animation.track_get_key_time(track_index, key_index)
            if t < start or t > finish:
                animation.track_remove_key(track_index, key_index)
        var remaining: int = animation.track_get_key_count(track_index)
        for key_index in range(remaining):
            var shifted: float = max(0.0, animation.track_get_key_time(track_index, key_index) - start)
            animation.track_set_key_time(track_index, key_index, shifted)
    animation.length = max(0.05, finish - start)

static func _find_animation_player(root: Node) -> AnimationPlayer:
    if root is AnimationPlayer:
        return root
    for child in root.get_children():
        var found: AnimationPlayer = _find_animation_player(child)
        if found != null:
            return found
    return null

static func _clean_name(value: String) -> String:
    var s: String = value.strip_edges().replace(" ", "_").replace("-", "_")
    return s

static func _strip_root_motion(animation: Animation) -> void:
    # Mixamo clips often contain Hips translation. The CharacterBody3D owns movement,
    # so leaving this track enabled makes the visual character slide or fight the joystick.
    for i in range(animation.get_track_count()):
        var path: NodePath = animation.track_get_path(i)
        var text: String = str(path).to_lower()
        if animation.track_get_type(i) == Animation.TYPE_VALUE and text.contains("position") and (text.contains("hips") or text.contains("root") or text.contains("armature")):
            animation.track_set_enabled(i, false)

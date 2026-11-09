extends CharacterBody3D

@export var walk_speed := 1.75
@export var run_speed := 3.45
@export var crouch_speed := 1.00
@export var acceleration := 8.0
@export var deceleration := 10.0
@export var rotation_speed := 5.8
@export var gravity := 18.0

var hp := 100
var crouching := false
var blocking := false
var mobile_move := Vector2.ZERO
var mobile_sprint := false
var mobile_block := false
var mobile_control_active := false
var hand_attachment: BoneAttachment3D
var combat: CombatSystem
var camera_rig
var animation_player: AnimationPlayer
var current_anim := ""
var animation_ready := false
var footstep_timer := 0.0
var weapon_mesh: Node3D
var weapon_root: Node3D
var knife_hold_time := 0.0
var knife_pressed := false
var mobile_aiming := false
var visual_stand_y := 0.06
var mobile_fire_held := false
var action_anim_timer := 0.0
var locomotion_time := 0.0
@export var visual_height_offset := 0.08
signal state_changed

func _ready():
    hp = GameState.hp
    velocity = Vector3.ZERO
    combat = CombatSystem.new()
    add_child(combat)
    camera_rig = $CameraRig
    animation_player = _find_animation_player($Visual)
    if animation_player:
        animation_player.active = true
        # Use the animation embedded in the Rokoko FBX for this test character.
        # The previous build copied Mixamo/Rokoko tracks between different skeleton paths,
        # which left the Rokoko mesh in a T-pose. Full retargeting will be done later on the real GP mesh.
        animation_ready = _has_embedded_animation(animation_player)
        if animation_ready:
            call_deferred("_play_embedded_animation")
    _prepare_visual()
    _apply_character_materials($Visual)
    _create_weapon_visuals()
    call_deferred("_attach_weapon_to_hand")

func _has_embedded_animation(player: AnimationPlayer) -> bool:
    for lib_name: StringName in player.get_animation_library_list():
        var lib: AnimationLibrary = player.get_animation_library(lib_name)
        if lib == null:
            continue
        for anim_name: StringName in lib.get_animation_list():
            if str(anim_name) != "RESET":
                return true
    return false

func _embedded_animation_name() -> StringName:
    for lib_name: StringName in animation_player.get_animation_library_list():
        var lib: AnimationLibrary = animation_player.get_animation_library(lib_name)
        if lib == null:
            continue
        for anim_name: StringName in lib.get_animation_list():
            if str(anim_name) != "RESET":
                return StringName(str(lib_name) + "/" + str(anim_name) if str(lib_name) != "" else str(anim_name))
    return StringName()

func _play_embedded_animation() -> void:
    var anim_name := _embedded_animation_name()
    if anim_name == StringName():
        return
    current_anim = str(anim_name)
    animation_player.play(anim_name, 0.12)

func _find_animation_player(root: Node) -> AnimationPlayer:
    if root is AnimationPlayer:
        return root
    for child in root.get_children():
        var found := _find_animation_player(child)
        if found != null:
            return found
    return null

func play_anim(name: String, loop := true):
    if not animation_ready or animation_player == null:
        return
    var lib: AnimationLibrary = animation_player.get_animation_library("")
    if lib == null:
        return
    var play_name: StringName = StringName(name)
    if not lib.has_animation(play_name):
        var embedded := _embedded_animation_name()
        if embedded == StringName():
            return
        play_name = embedded
    if current_anim == str(play_name) and animation_player.is_playing():
        return
    current_anim = str(play_name)
    var anim: Animation = lib.get_animation(play_name)
    anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
    animation_player.assigned_animation = play_name
    animation_player.play(play_name, 0.18)

func set_mobile_move(v: Vector2) -> void:
    mobile_move = v
    mobile_control_active = v.length() > 0.05
    if not mobile_control_active:
        velocity.x = 0.0
        velocity.z = 0.0

func set_mobile_sprint(v: bool) -> void:
    mobile_sprint = v

func set_mobile_block(v: bool) -> void:
    mobile_block = v

func toggle_crouch():
    crouching = !crouching
    _apply_crouch_collision()
    state_changed.emit()

func _apply_crouch_collision() -> void:
    var cs := get_node_or_null("CollisionShape3D") as CollisionShape3D
    if cs == null:
        return
    var shape := cs.shape as CapsuleShape3D
    if shape == null:
        shape = CapsuleShape3D.new()
        shape.radius = 0.32
        cs.shape = shape
    if crouching:
        shape.height = 1.10
        cs.position.y = 0.55
        var tw := create_tween()
        tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
        # Keep the feet on the same floor reference used by the standing pose.
        tw.tween_property($Visual, "position:y", max(0.02, visual_stand_y - 0.34), 0.16)
    else:
        shape.height = 1.80
        cs.position.y = 0.90
        var tw2 := create_tween()
        tw2.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
        tw2.tween_property($Visual, "position:y", visual_stand_y, 0.16)

func _physics_process(delta):
    action_anim_timer = max(0.0, action_anim_timer - delta)
    var input_vec: Vector2 = mobile_move if mobile_control_active else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var using_mobile: bool = mobile_control_active or mobile_sprint or mobile_block
    # On the mobile joystick, down must remain BACKWARD movement, not blocking.
    blocking = (input_vec.y > 0.55) and not using_mobile and not crouching
    var sprinting: bool = ((mobile_sprint or (using_mobile and input_vec.y > 0.68)) if using_mobile else abs(input_vec.y) > 0.68) and not crouching and not blocking
    if Input.is_action_just_pressed("crouch"):
        toggle_crouch()
    var speed := crouch_speed if crouching else (run_speed if sprinting else walk_speed)
    var cam_yaw: float = camera_rig.yaw
    var local: Vector3 = Vector3(input_vec.x, 0.0, input_vec.y)
    var dir := Vector3.ZERO
    if local.length() > 0.01:
        local = local.normalized()
        dir = Basis(Vector3.UP, cam_yaw) * local
        var target_angle: float = atan2(-dir.x, -dir.z)
        rotation.y = lerp_angle(rotation.y, target_angle, min(1.0, rotation_speed * delta))
    var lateral_factor: float = 0.72 if abs(input_vec.x) > abs(input_vec.y) else 1.0
    var backward_factor: float = 1.0
    var target_vel: Vector3 = dir * speed * lateral_factor * backward_factor if not blocking else Vector3.ZERO
    if camera_rig != null and camera_rig.has_method("set_rear_tracking"):
        camera_rig.set_rear_tracking(input_vec.y > 0.55)
    var rate: float = acceleration if target_vel.length() > 0.01 else deceleration
    velocity.x = move_toward(velocity.x, target_vel.x, rate * delta)
    velocity.z = move_toward(velocity.z, target_vel.z, rate * delta)
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0
    move_and_slide()

    if Input.is_action_just_pressed("fire"):
        mobile_fire()
    if mobile_fire_held and combat != null and combat.weapon == "Uzi":
        mobile_fire()
    if Input.is_action_pressed("aim"):
        combat.set_aiming(true)
    elif not mobile_aiming:
        combat.set_aiming(false)
    if Input.is_action_just_pressed("reload"):
        mobile_reload()
    if Input.is_action_just_pressed("knife"):
        mobile_knife()
    if Input.is_action_just_pressed("weapon_pistol"):
        mobile_equip("Pistol")
    if Input.is_action_just_pressed("weapon_shotgun"):
        mobile_equip("Shotgun")
    if Input.is_action_just_pressed("weapon_uzi"):
        mobile_equip("Uzi")
    if Input.is_action_just_pressed("weapon_rocket"):
        mobile_equip("RocketLauncher")

    if input_vec.length() > 0.05 and action_anim_timer <= 0.0:
        locomotion_time += delta
        # The current Rokoko test clip contains a turn later in the take.
        # Loop only its forward/back locomotion section so the character never
        # turns by itself while the player is still holding the same direction.
        if locomotion_time >= 3.25:
            locomotion_time = 0.35
            var embedded_loop := _embedded_animation_name()
            if embedded_loop != StringName() and animation_player != null:
                animation_player.play(embedded_loop, 0.12)
                animation_player.seek(0.35, true)
                current_anim = str(embedded_loop)
    else:
        locomotion_time = 0.0
    _update_animation(input_vec, sprinting)
    _update_footsteps(delta, target_vel)

func mobile_fire() -> void:
    if combat == null:
        return
    combat.fire()
    # No fake Mixamo-style fallback animation in this mocap test build.
    # The real firing/recoil animation will be retargeted onto the final skinned GP later.
    action_anim_timer = 0.0

func mobile_fire_down() -> void:
    mobile_fire_held = true
    mobile_fire()

func mobile_fire_up() -> void:
    mobile_fire_held = false

func mobile_aim_down() -> void:
    mobile_aiming = true
    if combat:
        combat.set_aiming(true)

func mobile_aim_up() -> void:
    mobile_aiming = false
    if combat:
        combat.set_aiming(false)

func mobile_toggle_aim() -> void:
    mobile_aiming = not mobile_aiming
    if combat:
        combat.set_aiming(mobile_aiming)

func mobile_reload() -> void:
    if combat == null:
        return
    var reloaded: bool = combat.reload()
    if not reloaded:
        return
    if combat.weapon == "Shotgun":
        if animation_ready:
            var duration: float = 2.2
            var lib: AnimationLibrary = animation_player.get_animation_library("") if animation_player != null else null
            if lib != null and lib.has_animation("Shotgun_reload"):
                duration = max(1.6, min(3.2, lib.get_animation("Shotgun_reload").length))
            action_anim_timer = duration
            play_anim("Shotgun_reload", false)
    elif combat.weapon == "Pistol":
        _weapon_reload_motion("Pistol")
    elif combat.weapon == "Uzi":
        _weapon_reload_motion("Uzi")
    elif combat.weapon == "RocketLauncher":
        _weapon_reload_motion("RocketLauncher")

func _weapon_reload_motion(kind: String) -> void:
    if weapon_root == null:
        return
    action_anim_timer = 0.85 if kind == "Pistol" else (1.05 if kind == "Uzi" else 1.15)
    var base_pos: Vector3 = Vector3(0.0, -0.12, -0.05)
    var base_rot: Vector3 = Vector3(-82.0, 4.0, 4.0)
    var down_pos: Vector3
    var down_rot: Vector3
    if kind == "Pistol":
        down_pos = base_pos + Vector3(-0.05, -0.13, 0.08)
        down_rot = base_rot + Vector3(8.0, -18.0, 6.0)
    elif kind == "Uzi":
        down_pos = base_pos + Vector3(0.07, -0.16, 0.05)
        down_rot = base_rot + Vector3(5.0, 14.0, -5.0)
    else:
        down_pos = base_pos + Vector3(0.0, -0.18, 0.10)
        down_rot = base_rot + Vector3(0.0, -8.0, 0.0)
    weapon_root.position = base_pos
    weapon_root.rotation_degrees = base_rot
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(weapon_root, "position", down_pos, 0.24)
    tween.parallel().tween_property(weapon_root, "rotation_degrees", down_rot, 0.24)
    tween.tween_interval(0.22 if kind != "Uzi" else 0.30)
    tween.tween_property(weapon_root, "position", base_pos, 0.28)
    tween.parallel().tween_property(weapon_root, "rotation_degrees", base_rot, 0.28)

func mobile_knife() -> void:
    if combat:
        combat.equip("Knife")
        combat.knife_attack()

func mobile_equip(name: String) -> void:
    if combat:
        combat.equip(name)

func _update_footsteps(delta: float, target_vel: Vector3) -> void:
    if target_vel.length() < 0.15 or not is_on_floor():
        footstep_timer = 0.0
        return
    footstep_timer -= delta
    if footstep_timer <= 0.0:
        AudioManager.play_footstep()
        footstep_timer = 0.34 if target_vel.length() > walk_speed + 0.3 else 0.52

func _hold_idle_pose() -> void:
    if not animation_ready or animation_player == null:
        return
    var embedded := _embedded_animation_name()
    if embedded == StringName():
        return
    # The imported Rokoko motion is a locomotion clip. Until the real skinned GP
    # gets its dedicated idle clip, hold a clean neutral frame from that clip.
    # This prevents the character from walking in place when the joystick is released.
    if current_anim != "__IDLE_POSE__" or animation_player.is_playing():
        animation_player.play(embedded, 0.08)
        animation_player.seek(0.50, true)
        animation_player.pause()
        current_anim = "__IDLE_POSE__"

func _update_animation(input_vec: Vector2, sprinting: bool):
    if not animation_ready:
        return
    if action_anim_timer > 0.0:
        return
    # For this Rokoko test build we only have locomotion mocap. Use it while moving
    # and hold a neutral frame while standing, instead of looping a walk cycle in place.
    if input_vec.length() <= 0.05:
        _hold_idle_pose()
        return
    var embedded := _embedded_animation_name()
    if embedded != StringName():
        if current_anim != str(embedded) or not animation_player.is_playing():
            animation_player.play(embedded, 0.10)
            current_anim = str(embedded)


func take_damage(amount: int):
    if blocking:
        amount = int(ceil(amount * 0.35))
    hp = clamp(hp - amount, 1, 100)
    GameState.hp = hp
    AudioManager.set_critical_health(hp <= 20)
    AudioManager.play_player_pain()
    state_changed.emit()

func heal_small():
    if GameState.small_medkits > 0:
        GameState.small_medkits -= 1
        hp = min(100, hp + 25)
        GameState.hp = hp
        state_changed.emit()

func heal_large():
    if GameState.large_medkits > 0:
        GameState.large_medkits -= 1
        hp = 100
        GameState.hp = hp
        state_changed.emit()



func _apply_character_materials(root: Node) -> void:
    for child in root.get_children():
        if child is MeshInstance3D:
            var mesh_node: MeshInstance3D = child
            var key := mesh_node.name.to_lower()
            var material := StandardMaterial3D.new()
            if key.contains("newton"):
                # Rokoko's exported test body is a single mesh; keep it neutral rather than the old pink statue color.
                material.albedo_color = Color(0.58, 0.48, 0.40)
            elif key.contains("hair") or (key.contains("head") and not key.contains("body")):
                material.albedo_color = Color(0.045, 0.035, 0.028)
            elif key.contains("shoe") or key.contains("boot") or key.contains("skirt") or key.contains("short"):
                material.albedo_color = Color(0.06, 0.045, 0.055)
            elif key.contains("shirt") or key.contains("top") or key.contains("cloth") or key.contains("torso"):
                material.albedo_color = Color(0.38, 0.18, 0.22)
            else:
                material.albedo_color = Color(0.66, 0.38, 0.28)
            material.roughness = 0.62
            mesh_node.material_override = material
        _apply_character_materials(child)

func _calculate_visual_floor_offset() -> float:
    # Keep the imported Rokoko mesh above the collision floor without changing the
    # CharacterBody baseline used by Build 12/14.
    var min_y: float = INF
    var stack: Array[Node] = [$Visual]
    while not stack.is_empty():
        var node: Node = stack.pop_back()
        if node is MeshInstance3D and node.mesh != null:
            var mesh_node := node as MeshInstance3D
            var aabb: AABB = mesh_node.get_aabb()
            var corners: Array[Vector3] = [
                Vector3(aabb.position.x, aabb.position.y, aabb.position.z),
                Vector3(aabb.end.x, aabb.position.y, aabb.position.z),
                Vector3(aabb.position.x, aabb.end.y, aabb.position.z),
                Vector3(aabb.position.x, aabb.position.y, aabb.end.z),
                Vector3(aabb.end.x, aabb.end.y, aabb.position.z),
                Vector3(aabb.end.x, aabb.position.y, aabb.end.z),
                Vector3(aabb.position.x, aabb.end.y, aabb.end.z),
                Vector3(aabb.end.x, aabb.end.y, aabb.end.z)
            ]
            for corner in corners:
                var world_corner: Vector3 = mesh_node.global_transform * corner
                min_y = min(min_y, world_corner.y)
        for child in node.get_children():
            stack.append(child)
    if min_y == INF:
        return visual_height_offset
    return max(0.0, -min_y + 0.005)

func _prepare_visual() -> void:
    # Keep the imported character close to the CharacterBody origin.
    # A small offset avoids the old floating/foot-through-floor mismatch.
    # Mixamo character origin is around the hips. Raise the visual so the soles meet floor y=0.
    visual_stand_y = _calculate_visual_floor_offset()
    $Visual.position.y = visual_stand_y
    # The Mixamo asset faces +Z while the CharacterBody/camera convention is -Z.
    # Rotate only the visual so gameplay movement/camera math stays unchanged.
    $Visual.rotation.y = PI
    $Visual.scale = Vector3.ONE

func _find_skeleton(root: Node) -> Skeleton3D:
    if root is Skeleton3D:
        return root
    for child in root.get_children():
        var found: Skeleton3D = _find_skeleton(child)
        if found != null:
            return found
    return null

func _attach_weapon_to_hand() -> void:
    var skeleton := _find_skeleton($Visual)
    if skeleton == null:
        return
    var bone_index := -1
    for candidate in ["mixamorig:RightHand", "RightHand", "mixamorig_RightHand"]:
        var idx := skeleton.find_bone(candidate)
        if idx >= 0:
            bone_index = idx
            break
    if bone_index < 0:
        return
    hand_attachment = BoneAttachment3D.new()
    hand_attachment.name = "WeaponHandAttachment"
    hand_attachment.bone_idx = bone_index
    skeleton.add_child(hand_attachment)
    weapon_root.reparent(hand_attachment, false)
    # Align the hand with the pistol grip rather than the slide/barrel.
    weapon_root.position = Vector3(0.00, -0.10, 0.04)
    weapon_root.rotation_degrees = Vector3(-82.0, 2.0, 2.0)
    weapon_root.scale = Vector3.ONE * 0.16

func _create_weapon_visuals():
    weapon_root = Node3D.new()
    weapon_root.name = "WeaponVisual"
    add_child(weapon_root)
    weapon_root.position = Vector3(0.0, 0.0, 0.0)
    weapon_root.scale = Vector3.ONE * 0.16
    weapon_mesh = Node3D.new()
    weapon_root.add_child(weapon_mesh)
    _build_pistol()
    _build_uzi()
    _build_shotgun()
    _build_rocket()
    _build_knife()
    _refresh_weapon_visual()

func _mat(c: Color, rough := 0.55) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = rough
    return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, c: Color):
    var mi := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mi.mesh = mesh
    mi.position = pos
    mi.material_override = _mat(c)
    parent.add_child(mi)
    return mi

func _cyl(parent: Node3D, radius: float, height: float, pos: Vector3, c: Color):
    var mi := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mi.mesh = mesh
    mi.position = pos
    mi.material_override = _mat(c)
    parent.add_child(mi)
    return mi

func _build_pistol():
    var n := Node3D.new(); n.name = "USP_S"; weapon_root.add_child(n)
    _box(n, Vector3(0.16,0.18,0.65), Vector3(0,0,0), Color(0.035,0.04,0.045))
    _box(n, Vector3(0.13,0.38,0.18), Vector3(0,-0.22,0.12), Color(0.055,0.06,0.065))
    _cyl(n,0.075,0.42,Vector3(0,0,0.52),Color(0.02,0.02,0.025)).rotation_degrees.x=90
    _cyl(n,0.09,0.34,Vector3(0,0,0.88),Color(0.015,0.015,0.018)).rotation_degrees.x=90

func _build_uzi():
    var n := Node3D.new(); n.name = "Uzi_Red"; weapon_root.add_child(n)
    _box(n, Vector3(0.16,0.18,0.78), Vector3(0,0,0), Color(0.8,0.015,0.02))
    _box(n, Vector3(0.12,0.36,0.2), Vector3(0,-0.22,0.12), Color(0.12,0.015,0.018))
    _box(n, Vector3(0.08,0.42,0.12), Vector3(0,-0.23,-0.23), Color(0.07,0.01,0.012))

func _build_shotgun():
    var n := Node3D.new(); n.name = "Shotgun"; weapon_root.add_child(n)
    _box(n, Vector3(0.18,0.18,0.85), Vector3(0,0,0), Color(0.09,0.075,0.055))
    _cyl(n,0.065,0.95,Vector3(0,0,0.72),Color(0.05,0.05,0.05)).rotation_degrees.x=90
    _box(n, Vector3(0.13,0.3,0.2), Vector3(0,-0.2,0.05), Color(0.15,0.09,0.05))

func _build_rocket():
    var n := Node3D.new(); n.name = "RocketLauncher"; weapon_root.add_child(n)
    _cyl(n,0.11,1.0,Vector3(0,0,0.2),Color(0.16,0.18,0.15)).rotation_degrees.x=90
    _box(n, Vector3(0.16,0.22,0.25), Vector3(0,-0.17,-0.05), Color(0.07,0.07,0.07))

func _build_knife():
    var n := Node3D.new(); n.name = "Knife"; weapon_root.add_child(n)
    _box(n, Vector3(0.05,0.08,0.5), Vector3(0,0,0.25), Color(0.7,0.72,0.74))
    _box(n, Vector3(0.08,0.1,0.22), Vector3(0,-0.02,-0.08), Color(0.05,0.04,0.035))

func _refresh_weapon_visual():
    if weapon_root == null or combat == null:
        return
    for child in weapon_root.get_children():
        child.visible = false
    var wanted: String = "USP_S"
    if combat.weapon == "Uzi":
        wanted = "Uzi_Red"
    elif combat.weapon == "Shotgun":
        wanted = "Shotgun"
    elif combat.weapon == "RocketLauncher":
        wanted = "RocketLauncher"
    elif combat.weapon == "Knife":
        wanted = "Knife"
    var node := weapon_root.get_node_or_null(wanted)
    if node != null:
        node.visible = true
    weapon_root.visible = true

func set_weapon_visual(w):
    if combat:
        combat.weapon = w
        _refresh_weapon_visual()

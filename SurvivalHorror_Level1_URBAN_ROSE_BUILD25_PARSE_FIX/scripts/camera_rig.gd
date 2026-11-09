extends Node3D

@export var distance := 3.25
@export var rear_distance := 4.60
@export var height := 1.72
@export var shoulder := 0.20
@export var aim_distance := 2.15
@export var aim_height := 1.52
@export var aim_shoulder := 0.52
@export var normal_fov := 56.0
@export var aim_fov := 43.0
@export var pitch_min := -0.48
@export var pitch_max := 0.34

var yaw := 0.0
var pitch := -0.10
var cinematic := false
var rear_tracking := false

func rotate_look(delta: Vector2) -> void:
    if cinematic:
        return
    var p = get_parent()
    var sensitivity: float = GameState.aim_sensitivity if p.combat.is_aiming else GameState.camera_sensitivity
    yaw -= delta.x * sensitivity
    pitch = clamp(pitch - delta.y * sensitivity, pitch_min, pitch_max)

func set_cinematic(active: bool) -> void:
    cinematic = active

func set_rear_tracking(active: bool) -> void:
    rear_tracking = active

func _process(_delta: float) -> void:
    var p = get_parent()
    var crouch_drop: float = 0.42 if p.crouching else 0.0
    global_position = p.global_position + Vector3.UP * (1.28 - crouch_drop)
    var aiming: bool = p.combat.is_aiming
    var dist: float = aim_distance if aiming else (rear_distance if rear_tracking else distance)
    var h: float = aim_height if aiming else height
    var side: float = aim_shoulder if aiming else shoulder

    var orbit_basis := Basis.from_euler(Vector3(pitch, yaw, 0.0))
    var desired: Vector3 = global_position + orbit_basis * Vector3(side, h - 1.28, dist)
    var target: Vector3 = global_position + Vector3.UP * (0.35 - (0.10 if p.crouching else 0.0)) + orbit_basis * Vector3(side * 0.12, 0.0, -0.9)

    var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.15, desired)
    q.exclude = [p]
    var hit = get_world_3d().direct_space_state.intersect_ray(q)
    if hit:
        $Camera3D.global_position = hit.position + hit.normal * 0.12
    else:
        $Camera3D.global_position = desired
    $Camera3D.look_at(target, Vector3.UP)
    $Camera3D.fov = aim_fov if aiming else normal_fov

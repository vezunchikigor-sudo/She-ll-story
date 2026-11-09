extends CharacterBody3D

@export var max_hp := 120
@export var move_speed := 1.215
@export var attack_damage := 9
var hp := 55
var target: CharacterBody3D
var attack_cd := 0.0
var aware := false

func _ready() -> void:
    hp = max_hp
    add_to_group("enemy")
    _build_zombie_visual()

func _mat(c: Color, rough := 0.82) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = rough
    return m

func _mesh(mesh: Mesh, pos: Vector3, mat: Material, scale := Vector3.ONE) -> MeshInstance3D:
    var mi := MeshInstance3D.new()
    mi.mesh = mesh
    mi.position = pos
    mi.scale = scale
    mi.material_override = mat
    add_child(mi)
    return mi

func _build_zombie_visual() -> void:
    var old := get_node_or_null("Mesh")
    if old:
        old.queue_free()
    var skin := _mat(Color(0.30, 0.34, 0.29))
    var cloth := _mat(Color(0.08, 0.075, 0.065))
    var dark := _mat(Color(0.035, 0.03, 0.025))

    var torso := BoxMesh.new()
    torso.size = Vector3(0.62, 0.82, 0.34)
    _mesh(torso, Vector3(0, 1.15, 0), cloth)
    var head := SphereMesh.new()
    head.radius = 0.30
    head.height = 0.60
    _mesh(head, Vector3(0, 1.78, 0), skin)
    var arm := CylinderMesh.new()
    arm.top_radius = 0.105
    arm.bottom_radius = 0.12
    arm.height = 0.78
    var left_arm := _mesh(arm, Vector3(-0.43, 1.17, 0), skin)
    left_arm.rotation_degrees = Vector3(0, 0, -14)
    var right_arm := _mesh(arm, Vector3(0.43, 1.17, 0), skin)
    right_arm.rotation_degrees = Vector3(0, 0, 14)
    var leg := BoxMesh.new()
    leg.size = Vector3(0.22, 0.82, 0.24)
    _mesh(leg, Vector3(-0.18, 0.45, 0), dark)
    _mesh(leg, Vector3(0.18, 0.45, 0), dark)

func take_damage(amount: int, zone := "body") -> void:
    hp -= amount
    AudioManager.play_enemy_pain()
    if hp <= 0:
        queue_free()
        return
    aware = true

func _physics_process(delta: float) -> void:
    attack_cd = max(0.0, attack_cd - delta)
    if not target:
        target = get_tree().get_first_node_in_group("player")
    if not target:
        return
    var d: Vector3 = target.global_position - global_position
    d.y = 0
    var dist: float = d.length()
    if not aware and dist > 5.5:
        velocity = Vector3.ZERO
        return
    aware = true
    if dist > 1.45:
        velocity = d.normalized() * move_speed
        rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z), delta * 5.0)
        move_and_slide()
    elif attack_cd <= 0.0:
        velocity = Vector3.ZERO
        target.take_damage(attack_damage)
        attack_cd = 0.8

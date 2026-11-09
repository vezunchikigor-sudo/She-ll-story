extends CharacterBody3D
signal rescued
var used := false
var hp := 70
var hidden := true
var target_hide := Vector3.ZERO
var move_timer := 0.0

func _ready():
    add_to_group("survivor")
    target_hide = global_position

func interact(_player):
    if used: return "Выживший уже получил лекарство"
    if GameState.survivor_medicine <= 0: return "Лекарство уже использовано"
    GameState.survivor_medicine -= 1
    used = true
    rescued.emit()
    return "Лекарство передано. Выживший спасён."

func take_damage(amount: int, _zone := "body"):
    if used: return
    hp = max(0, hp - amount)
    if hp <= 0:
        used = true
        visible = false

func _physics_process(delta):
    if used: return
    move_timer -= delta
    var enemies = get_tree().get_nodes_in_group("enemy")
    var nearest = null
    var nearest_dist := 999.0
    for e in enemies:
        var d = global_position.distance_to(e.global_position)
        if d < nearest_dist:
            nearest_dist = d
            nearest = e
    if nearest and nearest_dist < 4.0 and move_timer <= 0.0:
        var away = (global_position - nearest.global_position)
        away.y = 0
        if away.length() > 0.1:
            target_hide = global_position + away.normalized() * 2.2
        move_timer = 2.0
    if global_position.distance_to(target_hide) > 0.25:
        var dir = global_position.direction_to(target_hide)
        dir.y = 0
        velocity = dir.normalized() * 0.75
        move_and_slide()
        rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), delta * 3.0)
    else:
        velocity = Vector3.ZERO

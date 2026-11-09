extends CharacterBody3D
signal defeated
@export var max_hp := 4000
var hp := 4000
var target
var attack_cd := 0.0

func _ready():
    hp = max_hp
    add_to_group("enemy")
    add_to_group("boss")

func take_damage(amount: int, _zone := "body"):
    hp -= amount
    if hp <= 0:
        defeated.emit()
        queue_free()

func _physics_process(delta):
    attack_cd = max(0.0, attack_cd - delta)
    if not target:
        target = get_tree().get_first_node_in_group("player")
    if not target:
        return
    # The boss stays in his arena. The player must approach him instead of
    # being chased across the level.
    velocity = Vector3.ZERO
    var d: Vector3 = target.global_position - global_position
    d.y = 0
    if d.length() <= 2.15 and attack_cd <= 0.0:
        target.take_damage(18)
        attack_cd = 1.0

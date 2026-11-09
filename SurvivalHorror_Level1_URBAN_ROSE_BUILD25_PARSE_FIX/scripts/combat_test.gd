extends Node3D

@onready var player=$Player
@onready var camera=$Player/CameraRig/Camera3D
var enemy_scene=preload("res://scenes/enemy.tscn")
var spawn_points=[Vector3(0,1,-8),Vector3(5,1,-5),Vector3(-6,1,-10),Vector3(7,1,-12)]
var enemies=[]

func _ready():
    for i in spawn_points.size():
        var e=enemy_scene.instantiate(); add_child(e); e.global_position=spawn_points[i]
        e.setup(player,100+i*50,1.15+float(i)*0.15,"LightType1" if i<2 else "HardType1")
        enemies.append(e)
    player.combat.hit_confirmed.connect(_on_attack)

func _on_attack():
    var origin=camera.global_position
    var forward=-camera.global_transform.basis.z
    var reach=2.4 if player.combat.weapon=="Knife" else 35.0
    var query=PhysicsRayQueryParameters3D.create(origin,origin+forward*reach)
    query.exclude=[player]
    var hit=get_world_3d().direct_space_state.intersect_ray(query)
    if hit and hit.collider.has_method("take_damage"):
        hit.collider.take_damage(player.combat.damage[player.combat.weapon])

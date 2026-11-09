extends Node
class_name CombatSystem

var weapon := "Pistol"
var ammo := 12
var reserve := 120
var is_aiming := false
var cooldown := 0.0
var knife_alt := false

func _process(delta):
    cooldown = max(0.0, cooldown - delta)

func set_aiming(v):
    is_aiming = v
    if get_parent().has_method("_refresh_weapon_visual"):
        get_parent()._refresh_weapon_visual()

func equip(w):
    weapon = w
    if w == "Pistol": ammo = 12
    elif w == "Shotgun": ammo = 6
    elif w == "Uzi": ammo = 30
    elif w == "RocketLauncher": ammo = 1
    elif w == "Knife": ammo = 0
    reserve = GameState.weapon_reserve.get(w, 0)
    if get_parent().has_method("_refresh_weapon_visual"):
        get_parent()._refresh_weapon_visual()

func fire():
    if weapon == "Knife":
        knife_attack()
        return
    if cooldown > 0 or ammo <= 0:
        return
    ammo -= 1
    if weapon == "Uzi": cooldown = 0.11
    elif weapon == "Shotgun": cooldown = 0.85
    elif weapon == "RocketLauncher": cooldown = 1.2
    else: cooldown = 0.28
    GameState.weapon_reserve[weapon] = reserve
    var cam = get_parent().get_node("CameraRig/Camera3D")
    var from: Vector3 = cam.global_position
    var to: Vector3 = from + (-cam.global_transform.basis.z) * 300.0
    var q := PhysicsRayQueryParameters3D.create(from, to)
    q.exclude = [get_parent()]
    var hit = get_parent().get_world_3d().direct_space_state.intersect_ray(q)
    var damaged := false
    if hit and hit.collider.has_method("take_damage"):
        var distance_to_hit: float = from.distance_to(hit.position)
        var long_range_miss: bool = distance_to_hit > 20.0 and randf() < 0.05
        if not long_range_miss:
            var zone: String = _hit_zone(hit.position, hit.collider)
            hit.collider.take_damage(_weapon_damage(zone), zone)
            damaged = true
    # The boss has a large capsule and must remain reliably hittable at range.
    # If the camera ray passes just beside its collision capsule, use a narrow
    # forward cone fallback rather than wasting the shot.
    if not damaged:
        var best: Node = null
        var best_dist: float = 9999.0
        for candidate in get_tree().get_nodes_in_group("enemy"):
            if candidate == get_parent() or not candidate.has_method("take_damage"):
                continue
            var to_target: Vector3 = candidate.global_position - from
            var dist: float = to_target.length()
            if dist > 300.0 or dist >= best_dist:
                continue
            var forward_dot: float = (-cam.global_transform.basis.z).dot(to_target.normalized())
            var cone_width: float = 0.08 if candidate.is_in_group("boss") else 0.055
            if forward_dot >= 1.0 - cone_width:
                best = candidate
                best_dist = dist
        if best != null:
            var zone2: String = "body"
            best.take_damage(_weapon_damage(zone2), zone2)
    AudioManager.play_weapon(weapon)
    if weapon == "RocketLauncher":
        ammo = 0

func _weapon_damage(zone: String) -> int:
    if weapon == "Pistol":
        if zone == "head": return 50
        if zone == "limb": return 15
        return 22
    if weapon == "Shotgun":
        if zone == "head": return 100
        return 55
    if weapon == "Uzi":
        if zone == "head": return 35
        if zone == "limb": return 12
        return 18
    if weapon == "RocketLauncher": return 180
    return 10

func _hit_zone(pos: Vector3, collider: Node) -> String:
    var local: Vector3 = collider.to_local(pos)
    if local.y > 0.85: return "head"
    if abs(local.x) > 0.28 and local.y > 0.2: return "limb"
    if local.y < 0.15: return "limb"
    return "body"

func knife_attack():
    if cooldown > 0: return
    knife_alt = !knife_alt
    cooldown = 0.5 if knife_alt else 0.8
    var player = get_parent()
    var cam = player.get_node("CameraRig/Camera3D")
    var from = player.global_position + Vector3.UP * 1.0
    var forward = -cam.global_transform.basis.z
    var to = from + forward * 2.0
    var q := PhysicsRayQueryParameters3D.create(from, to)
    q.exclude = [player]
    var hit = player.get_world_3d().direct_space_state.intersect_ray(q)
    if hit and hit.collider.has_method("take_damage"):
        var zone := _hit_zone(hit.position, hit.collider)
        var damage := 25 if knife_alt else 15
        if zone == "head": damage = 50
        elif zone == "limb": damage = 10 if knife_alt else 8
        hit.collider.take_damage(damage, zone)
    AudioManager.play_weapon("Knife")
    if player.has_method("play_anim"):
        player.action_anim_timer = 0.75 if knife_alt else 0.60
        player.play_anim("Stabbing" if knife_alt else "knife", false)

func reload() -> bool:
    var cap: int = 12 if weapon == "Pistol" else (6 if weapon == "Shotgun" else (30 if weapon == "Uzi" else 1))
    if ammo >= cap or reserve <= 0:
        return false
    var need: int = cap - ammo
    var give: int = min(need, reserve)
    ammo += give
    reserve -= give
    GameState.weapon_reserve[weapon] = reserve
    AudioManager.play_reload()
    return true

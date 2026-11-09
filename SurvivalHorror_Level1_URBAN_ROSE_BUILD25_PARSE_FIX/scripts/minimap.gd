extends Control
class_name LevelMiniMap

var player: Node3D
var level: Node3D
var expanded := false
var radius_m := 3.0
var full_padding := 18.0
var level_min := Vector2(-24.0, -18.0)
var level_max := Vector2(24.0, 18.0)
var map_texture: Texture2D

func setup(level_node: Node3D, player_node: Node3D) -> void:
    level = level_node
    player = player_node
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_process_input(true)
    z_index = 160
    var loaded: Resource = ResourceLoader.load("res://art/reference/mansion_floor1_map.jpg")
    if loaded is Texture2D:
        map_texture = loaded as Texture2D
    queue_redraw()

func _process(_delta: float) -> void:
    if player != null:
        queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        if touch.pressed and _point_hits_map(touch.position):
            _toggle_expanded()
            accept_event()
    elif event is InputEventMouseButton:
        var mb: InputEventMouseButton = event
        if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and _point_hits_map(mb.position):
            _toggle_expanded()
            accept_event()

func _point_hits_map(point: Vector2) -> bool:
    if expanded:
        var side: float = min(size.x, size.y)
        var rect := Rect2((size.x-side)*0.5, (size.y-side)*0.5, side, side)
        return rect.has_point(point)
    var side_small: float = min(size.x, size.y) * 0.275
    var rect_small := Rect2(size.x - side_small - 14.0, 14.0, side_small, side_small)
    return rect_small.has_point(point)

func _toggle_expanded() -> void:
    expanded = not expanded
    if expanded:
        anchor_left = 0.0; anchor_top = 0.0; anchor_right = 1.0; anchor_bottom = 1.0
    else:
        anchor_left = 0.72; anchor_top = 0.01; anchor_right = 0.995; anchor_bottom = 0.30
    offset_left = 0.0; offset_top = 0.0; offset_right = 0.0; offset_bottom = 0.0
    z_index = 500 if expanded else 160
    queue_redraw()

func _draw() -> void:
    if player == null or level == null: return
    if expanded: _draw_expanded()
    else: _draw_local()

func _draw_local() -> void:
    var side: float = min(size.x, size.y)
    var rect := Rect2(size.x - side - 14.0, 14.0, side, side)
    _draw_frame(rect)
    _draw_local_plan(rect)
    _draw_static_objects(rect, func(pos: Vector3) -> Vector2: return _local_to_rect(pos, rect))
    _draw_dynamic_objects(rect, func(pos: Vector3) -> Vector2: return _local_to_rect(pos, rect))

func _draw_expanded() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0,0,0,0.96), true)
    var side: float = min(size.x, size.y) - full_padding * 2.0
    var rect := Rect2((size.x-side)*0.5, (size.y-side)*0.5, side, side)
    _draw_frame(rect)
    if map_texture != null:
        draw_texture_rect(map_texture, rect, true, Color(1,1,1,0.96))
    _draw_static_objects(rect, func(pos: Vector3) -> Vector2: return _full_to_rect(pos, rect))
    _draw_dynamic_objects(rect, func(pos: Vector3) -> Vector2: return _full_to_rect(pos, rect))
    draw_string(ThemeDB.fallback_font, rect.position+Vector2(18,30), "КАРТА УРОВНЯ", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1,1,1,0.92))
    draw_string(ThemeDB.fallback_font, Vector2(rect.position.x+18,rect.end.y-18), "НАЖМИТЕ НА КАРТУ, ЧТОБЫ ЗАКРЫТЬ", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1,1,1,0.82))
    _draw_legend(rect)

func _draw_frame(rect: Rect2) -> void:
    if map_texture == null: draw_rect(rect, Color(0.04,0.04,0.04,0.96), true)
    draw_rect(rect, Color(0.85,0.72,0.46,0.95), false, 3.0)

func _draw_local_plan(rect: Rect2) -> void:
    if map_texture == null: return
    var ts: Vector2 = map_texture.get_size()
    var src_size := Vector2((radius_m*2.0)/(level_max.x-level_min.x)*ts.x, (radius_m*2.0)/(level_max.y-level_min.y)*ts.y)
    var u: float = clamp((player.global_position.x-level_min.x)/(level_max.x-level_min.x),0.0,1.0)
    var v: float = clamp((player.global_position.z-level_min.y)/(level_max.y-level_min.y),0.0,1.0)
    var src := Vector2(u*ts.x, v*ts.y)-src_size*0.5
    src.x = clamp(src.x,0.0,max(0.0,ts.x-src_size.x)); src.y = clamp(src.y,0.0,max(0.0,ts.y-src_size.y))
    draw_texture_rect_region(map_texture, rect, Rect2(src,src_size), Color(1,1,1,0.96))
    draw_arc(rect.get_center(), rect.size.x*0.5, 0, TAU, 64, Color(0.2,0.65,1.0,0.30), 1.0)

func _full_to_rect(pos: Vector3, rect: Rect2) -> Vector2:
    var u: float = clamp((pos.x-level_min.x)/(level_max.x-level_min.x),0.0,1.0)
    var v: float = clamp((pos.z-level_min.y)/(level_max.y-level_min.y),0.0,1.0)
    return Vector2(rect.position.x+u*rect.size.x, rect.position.y+v*rect.size.y)

func _local_to_rect(pos: Vector3, rect: Rect2) -> Vector2:
    var c := rect.get_center(); var scale_px: float = rect.size.x/(radius_m*2.0)
    return c+Vector2(pos.x-player.global_position.x,pos.z-player.global_position.z)*scale_px

func _draw_static_objects(rect: Rect2, mapper: Callable) -> void:
    var local_scale: float = rect.size.x/(radius_m*2.0) if rect.size.x <= 260.0 else min(rect.size.x/(level_max.x-level_min.x),rect.size.y/(level_max.y-level_min.y))
    for child in level.get_children():
        if child.has_meta("map_size"):
            var mp: Vector2 = mapper.call(child.global_position)
            var ws: Vector3 = child.get_meta("map_size")
            var sz := Vector2(ws.x*local_scale,ws.z*local_scale)
            var kind: String = str(child.get_meta("map_kind","wall"))
            if kind == "floor": continue
            if _visible(mp,rect):
                var fill := Color(0.03,0.08,0.20,0.88) if kind == "wall" else Color(0.50,0.28,0.10,0.90)
                if kind == "door": fill=Color(0.82,0.62,0.12,0.98)
                draw_rect(Rect2(mp-sz*0.5,sz),fill,true)
        elif child.has_meta("map_point"):
            var mp2: Vector2=mapper.call(child.global_position)
            if _visible(mp2,rect): draw_circle(mp2,3.0,Color(0.55,0.38,0.20,0.95))

func _draw_dynamic_objects(rect: Rect2, mapper: Callable) -> void:
    var pp: Vector2=mapper.call(player.global_position)
    if _visible(pp,rect):
        draw_circle(pp,7.0,Color(0.25,0.80,1.0,1.0))
        draw_line(pp,pp+Vector2(-sin(player.rotation.y),cos(player.rotation.y))*13.0,Color(0.25,0.80,1.0,1.0),3.0)
    for enemy in get_tree().get_nodes_in_group("enemy"):
        if enemy is Node3D:
            var ep: Vector2=mapper.call((enemy as Node3D).global_position)
            if _visible(ep,rect): draw_circle(ep,5.0,Color(0.92,0.16,0.12,1.0))
    for survivor in get_tree().get_nodes_in_group("survivor"):
        if survivor is Node3D:
            var sp: Vector2=mapper.call((survivor as Node3D).global_position)
            if _visible(sp,rect): draw_circle(sp,5.0,Color(0.25,0.88,0.40,1.0))

func _draw_legend(rect: Rect2) -> void:
    var y: float=rect.position.y+54.0
    draw_circle(Vector2(rect.position.x+28,y),6.0,Color(0.25,0.80,1.0,1.0)); draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+42,y+6),"ГП",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(1,1,1,0.85))
    draw_circle(Vector2(rect.position.x+88,y),6.0,Color(0.92,0.16,0.12,1.0)); draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+102,y+6),"Противник",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(1,1,1,0.85))
    draw_circle(Vector2(rect.position.x+208,y),6.0,Color(0.25,0.88,0.40,1.0)); draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+222,y+6),"ВП",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(1,1,1,0.85))

func _visible(point: Vector2, rect: Rect2) -> bool:
    return rect.grow(18.0).has_point(point)

extends Node3D

var survivor
var boss
var message_label
var completed := false
var cutscene
var boss_started := false
var boss_door: StaticBody3D

const WALL_H: float = 6.0 # два уровня по 3 м
const ROOM_W: float = 15.0 # длина слева направо в обоих помещениях
const HALL_D: float = 10.0
const LIB_D: float = 8.0

func mat(c: Color, rough: float = 0.78, metallic: float = 0.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = rough
    m.metallic = metallic
    return m

func box(parent: Node3D, pos: Vector3, size: Vector3, c: Color, map_kind: String = "wall", collision: bool = true, material: StandardMaterial3D = null) -> Node3D:
    var root: Node3D = StaticBody3D.new() if collision else Node3D.new()
    root.position = pos
    parent.add_child(root)
    var mi := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mi.mesh = mesh
    mi.material_override = material if material != null else mat(c)
    root.add_child(mi)
    if collision:
        var cs := CollisionShape3D.new()
        var sh := BoxShape3D.new()
        sh.size = size
        cs.shape = sh
        root.add_child(cs)
    root.set_meta("map_size", size)
    root.set_meta("map_kind", map_kind)
    return root

func floor_tile(parent: Node3D, pos: Vector3, size: Vector3, material: StandardMaterial3D) -> Node3D:
    return box(parent, pos, size, Color.WHITE, "floor", false, material)

func add_herringbone_floor(origin: Vector3, size: Vector2) -> void:
    var wood_a := mat(Color(0.29, 0.105, 0.045), 0.62)
    var wood_b := mat(Color(0.20, 0.065, 0.026), 0.66)
    var board_len: float = 1.05
    var board_w: float = 0.24
    var z_count: int = int(size.y / (board_w * 2.0))
    for row in range(z_count):
        var z: float = origin.z - size.y * 0.5 + float(row) * board_w * 2.0 + board_w
        for col in range(int(size.x / board_len) + 2):
            var x: float = origin.x - size.x * 0.5 + float(col) * board_len - 0.25
            var vertical: bool = ((row + col) % 2) == 0
            var p := Vector3(x, -0.035, z)
            var s := Vector3(board_len, 0.07, board_w)
            var mi: Node3D = floor_tile(self, p, s, wood_a if ((row + col) % 3) != 0 else wood_b)
            mi.rotation.y = PI * 0.25 if vertical else -PI * 0.25
    box(self, Vector3(origin.x, -0.08, origin.z), Vector3(size.x, 0.16, size.y), Color(0.18,0.055,0.02), "floor_collision", true)

func add_trim_wall(pos: Vector3, size: Vector3, base: Color = Color(0.72,0.67,0.57)) -> void:
    var plaster := mat(base, 0.88)
    box(self, pos, size, base, "wall", true, plaster)
    var wood := mat(Color(0.20,0.075,0.032), 0.58)
    var lower_y: float = 0.62
    box(self, Vector3(pos.x, lower_y, pos.z), Vector3(size.x + 0.08, 0.16, size.z + 0.08), Color.WHITE, "trim", false, wood)
    box(self, Vector3(pos.x, WALL_H - 0.22, pos.z), Vector3(size.x + 0.10, 0.20, size.z + 0.10), Color.WHITE, "trim", false, wood)
    if size.x > size.z:
        box(self, Vector3(pos.x, 1.12, pos.z - 0.02), Vector3(size.x + 0.05, 0.10, 0.12), Color.WHITE, "trim", false, wood)
        box(self, Vector3(pos.x, 2.35, pos.z - 0.02), Vector3(size.x + 0.05, 0.10, 0.12), Color.WHITE, "trim", false, wood)
    else:
        box(self, Vector3(pos.x - 0.02, 1.12, pos.z), Vector3(0.12, 0.10, size.z + 0.05), Color.WHITE, "trim", false, wood)
        box(self, Vector3(pos.x - 0.02, 2.35, pos.z), Vector3(0.12, 0.10, size.z + 0.05), Color.WHITE, "trim", false, wood)

func add_door(center: Vector3, width: float = 2.6, height: float = 2.65, double: bool = true) -> StaticBody3D:
    var wood := mat(Color(0.10,0.028,0.012), 0.50)
    var frame := mat(Color(0.26,0.10,0.035), 0.52)
    var root := box(self, center + Vector3(0,height*0.5,0), Vector3(width,height,0.20), Color.WHITE, "door", true, wood) as StaticBody3D
    box(root, Vector3(0,0.04,-0.12), Vector3(width+0.34,height+0.28,0.12), Color.WHITE, "trim", false, frame)
    var half: float = width * 0.46 if double else 0.0
    for x in ([-half, half] if double else [0.0]):
        for y in [0.52, 1.25, 2.02]:
            box(root, Vector3(x,y-height*0.5,-0.13), Vector3(width*0.32,0.42,0.05), Color.WHITE, "door_panel", false, frame)
        cyl(root, Vector3(x + (0.32 if double else 0.0), 1.26-height*0.5,-0.18), 0.045, 0.10, Color(0.72,0.50,0.20), false)
    return root

func cyl(parent: Node3D, pos: Vector3, r: float, h: float, c: Color, collision: bool = false, material: StandardMaterial3D = null) -> Node3D:
    var root: Node3D = StaticBody3D.new() if collision else Node3D.new()
    root.position = pos
    parent.add_child(root)
    var mi := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = r
    mesh.bottom_radius = r * 1.05
    mesh.height = h
    mi.mesh = mesh
    mi.material_override = material if material != null else mat(c)
    root.add_child(mi)
    if collision:
        var cs := CollisionShape3D.new()
        var sh := CylinderShape3D.new()
        sh.radius = r
        sh.height = h
        cs.shape = sh
        root.add_child(cs)
    root.set_meta("map_point", true)
    root.set_meta("map_kind", "furniture")
    return root

func add_chandelier(center: Vector3) -> void:
    var brass := mat(Color(0.32,0.12,0.035),0.42,0.45)
    cyl(self, center + Vector3(0,1.15,0), 0.055, 2.3, Color.WHITE, false, brass)
    cyl(self, center + Vector3(0,0.08,0), 0.22, 0.16, Color.WHITE, false, brass)
    for i in range(8):
        var a: float = TAU * float(i) / 8.0
        var p := center + Vector3(cos(a)*1.0,0.08,sin(a)*1.0)
        cyl(self, p, 0.035, 0.65, Color.WHITE, false, brass)
        var lamp := OmniLight3D.new()
        lamp.position = p + Vector3(0,0.35,0)
        lamp.omni_range = 4.8
        lamp.light_energy = 1.2
        lamp.light_color = Color(1.0,0.68,0.38)
        add_child(lamp)

func add_wall_sconce(pos: Vector3, rot_y: float = 0.0) -> void:
    var brass := mat(Color(0.28,0.10,0.025),0.45,0.45)
    var root := Node3D.new()
    root.position = pos
    root.rotation.y = rot_y
    add_child(root)
    cyl(root, Vector3(0,0,0), 0.055, 0.22, Color.WHITE, false, brass)
    var lamp := OmniLight3D.new()
    lamp.position = Vector3(0,0.12,0)
    lamp.omni_range = 3.2
    lamp.light_energy = 0.75
    lamp.light_color = Color(1.0,0.58,0.30)
    root.add_child(lamp)

func add_stairs(x_center: float, z_start: float, direction: float) -> void:
    var wood := mat(Color(0.17,0.045,0.018),0.50)
    var carpet := mat(Color(0.20,0.025,0.025),0.88)
    var rail := mat(Color(0.13,0.035,0.014),0.48)
    var step_count: int = 12
    var step_depth: float = 0.42
    var step_h: float = 0.25
    for i in range(step_count):
        var y: float = step_h * float(i) + step_h * 0.5
        var z: float = z_start + direction * (float(i) * step_depth)
        box(self, Vector3(x_center,y,z), Vector3(2.55,step_h,step_depth+0.04), Color.WHITE, "stairs", true, wood)
        box(self, Vector3(x_center,y+0.012,z-direction*0.01), Vector3(1.42,0.035,step_depth+0.06), Color.WHITE, "carpet", false, carpet)
    var top_y: float = step_count * step_h
    for side in [-1.0,1.0]:
        var sx: float = x_center + side*1.22
        box(self, Vector3(sx,top_y*0.52,z_start + direction*(step_count-1)*step_depth*0.5), Vector3(0.10,top_y+0.08,step_count*step_depth+0.3), Color.WHITE, "rail_support", true, rail)
        for i in range(4):
            var zz: float = z_start + direction*(float(i*3)*step_depth)
            box(self, Vector3(sx,top_y*0.5,zz), Vector3(0.12,top_y+0.25,0.12), Color.WHITE, "rail_post", false, rail)
        box(self, Vector3(sx,top_y+0.25,z_start + direction*(step_count-1)*step_depth*0.5), Vector3(0.13,0.13,step_count*step_depth+0.35), Color.WHITE, "rail", false, rail)

func add_bookshelf_wall(z: float, x_center: float, width: float, height: float = 5.65) -> void:
    var wood := mat(Color(0.105,0.028,0.012),0.48)
    var shelf := mat(Color(0.16,0.048,0.018),0.52)
    box(self, Vector3(x_center,height*0.5,z), Vector3(width,height,0.36), Color.WHITE, "bookshelf", true, wood)
    var levels: int = int(height / 0.70)
    for row in range(levels):
        var y: float = 0.40 + float(row)*0.70
        box(self, Vector3(x_center,y,z-0.20), Vector3(width+0.04,0.085,0.44), Color.WHITE, "shelf", false, shelf)
        var count: int = max(1, int(width / 0.34))
        for i in range(count):
            var bx: float = x_center-width*0.47+float(i)*width/float(max(1,count-1))
            var book_h: float = 0.42+float((i*7+row*3)%6)*0.045
            var colors: Array[Color] = [Color(0.20,0.035,0.025),Color(0.10,0.13,0.085),Color(0.34,0.17,0.045),Color(0.12,0.04,0.12),Color(0.22,0.16,0.07)]
            box(self, Vector3(bx,y+0.045+book_h*0.5,z-0.23), Vector3(0.18,book_h,0.27), colors[(i+row)%colors.size()], "decor", false, mat(colors[(i+row)%colors.size()],0.72))

func add_bookshelf_side(x: float, z_center: float, depth: float, length: float, height: float = 3.35) -> void:
    var wood := mat(Color(0.105,0.028,0.012),0.48)
    box(self, Vector3(x,height*0.5,z_center), Vector3(depth,height,length), Color.WHITE, "bookshelf", true, wood)
    for z in [-length*0.46,-length*0.23,0.0,length*0.23,length*0.46]:
        box(self, Vector3(x-0.20,0.70,z_center+z), Vector3(depth+0.05,0.10,0.38), Color.WHITE, "shelf", true, wood)

func add_ladder(pos: Vector3) -> void:
    var wood := mat(Color(0.26,0.09,0.035),0.55)
    for x in [-0.50,0.50]:
        box(self, pos + Vector3(x,1.25,0), Vector3(0.11,2.5,0.11), Color.WHITE, "ladder", false, wood)
    for i in range(8):
        box(self, pos + Vector3(0,0.28+float(i)*0.30,0), Vector3(1.05,0.08,0.16), Color.WHITE, "ladder", false, wood)

func add_console(pos: Vector3) -> void:
    var wood := mat(Color(0.13,0.035,0.014),0.52)
    box(self,pos+Vector3(0,0.58,0),Vector3(1.55,0.16,0.50),Color.WHITE,"furniture",true,wood)
    for x in [-0.62,0.62]:
        box(self,pos+Vector3(x,0.28,0),Vector3(0.10,0.58,0.10),Color.WHITE,"furniture",true,wood)

func add_portrait(pos: Vector3, size: Vector2 = Vector2(0.85,1.10), rot_y: float = 0.0) -> void:
    var frame := mat(Color(0.30,0.12,0.035),0.46,0.2)
    box(self,pos,Vector3(size.x,size.y,0.07),Color(0.03,0.02,0.015),"decor",false,frame)
    box(self,pos+Vector3(0,0,-0.045),Vector3(size.x*0.82,size.y*0.82,0.02),Color(0.10,0.075,0.05),"decor",false)

func add_rug(pos: Vector3, size: Vector2, color: Color) -> void:
    box(self,pos+Vector3(0,0.012,0),Vector3(size.x,0.025,size.y),color,"decor",false,mat(color,0.96))
    box(self,pos+Vector3(0,0.027,0),Vector3(size.x*0.92,0.012,size.y*0.92),Color(0.20,0.025,0.025),"decor",false,mat(Color(0.20,0.025,0.025),0.98))

func add_ceiling(room_center: Vector3, size: Vector2) -> void:
    var cream := mat(Color(0.57,0.52,0.44),0.90)
    box(self,Vector3(room_center.x,WALL_H,room_center.z),Vector3(size.x,0.18,size.y),Color.WHITE,"ceiling",true,cream)
    var wood := mat(Color(0.20,0.075,0.03),0.58)
    for x in [-size.x*0.5+0.35,0.0,size.x*0.5-0.35]:
        box(self,Vector3(x,WALL_H-0.10,room_center.z),Vector3(0.14,0.18,size.y),Color.WHITE,"ceiling_trim",false,wood)
    box(self,Vector3(room_center.x,WALL_H-0.10,room_center.z),Vector3(size.x,0.18,0.14),Color.WHITE,"ceiling_trim",false,wood)

func _add_wall_panel(pos: Vector3, size: Vector2, rot_y: float = 0.0) -> void:
    var frame := mat(Color(0.30, 0.105, 0.035), 0.50)
    var inset := mat(Color(0.13, 0.045, 0.020), 0.70)
    var root := Node3D.new()
    root.position = pos
    root.rotation.y = rot_y
    add_child(root)
    box(root, Vector3.ZERO, Vector3(size.x, size.y, 0.055), Color.WHITE, "wall_panel_frame", false, frame)
    box(root, Vector3(0, 0, -0.034), Vector3(max(0.08, size.x-0.12), max(0.08, size.y-0.12), 0.025), Color.WHITE, "wall_panel_inset", false, inset)
    box(root, Vector3(-size.x*0.5+0.035, 0, -0.055), Vector3(0.035,size.y-0.06,0.035), Color.WHITE,"panel_molding",false,frame)
    box(root, Vector3(size.x*0.5-0.035, 0, -0.055), Vector3(0.035,size.y-0.06,0.035), Color.WHITE,"panel_molding",false,frame)

func _add_window(pos: Vector3, width: float = 1.55, height: float = 2.15, rot_y: float = 0.0) -> void:
    var frame := mat(Color(0.20,0.065,0.023),0.48)
    var glass := mat(Color(0.16,0.22,0.25,0.72),0.18,0.08)
    glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    var root := Node3D.new()
    root.position = pos
    root.rotation.y = rot_y
    add_child(root)
    box(root, Vector3(0,height*0.5,0), Vector3(width,height,0.10), Color.WHITE,"window_frame",false,frame)
    box(root, Vector3(0,height*0.5,-0.06), Vector3(width-0.14,height-0.14,0.025), Color.WHITE,"window_glass",false,glass)
    box(root, Vector3(0,height*0.5,-0.085), Vector3(0.055,height-0.08,0.035), Color.WHITE,"window_mullion",false,frame)
    box(root, Vector3(0,height*0.5,-0.09), Vector3(width-0.10,0.055,0.035), Color.WHITE,"window_mullion",false,frame)
    box(root, Vector3(0,0.03,0), Vector3(width+0.22,0.14,0.20), Color.WHITE,"window_sill",false,frame)

func _add_upper_gallery(center_x: float, center_z: float, width: float, depth: float) -> void:
    var wood := mat(Color(0.16,0.045,0.016),0.47)
    var rail := mat(Color(0.22,0.075,0.025),0.42)
    box(self,Vector3(center_x,3.02,center_z),Vector3(width,0.16,depth),Color.WHITE,"upper_gallery_floor",true,wood)
    for side in [-1.0,1.0]:
        var x: float = center_x + side*width*0.5
        box(self,Vector3(x,3.47,center_z),Vector3(0.10,0.88,depth),Color.WHITE,"gallery_rail",true,rail)
        for i in range(12):
            var z := center_z-depth*0.5+0.22+float(i)*(depth-0.44)/11.0
            box(self,Vector3(x-side*0.04,3.43,z),Vector3(0.055,0.74,0.055),Color.WHITE,"gallery_baluster",false,rail)
        box(self,Vector3(x,3.93,center_z),Vector3(0.16,0.12,depth+0.12),Color.WHITE,"gallery_handrail",false,wood)

func decor() -> void:
    # BUILD25: metrically corrected rooms, 3 m floor-to-floor, architectural trim and decor.
    # Hall: 15 x 10 m, x=-7.5..7.5, z=-1..9. Library: 15 x 8 m, x=-7.5..7.5, z=-9..-1.
    var hall_center_z := 4.0
    var lib_center_z := -5.0
    var hall_floor := mat(Color(0.70,0.67,0.61),0.25)
    var marble_dark := mat(Color(0.22,0.20,0.18),0.32)
    var mahogany := mat(Color(0.105,0.031,0.012),0.47)
    var gold := mat(Color(0.48,0.29,0.095),0.34,0.58)
    var cream := mat(Color(0.70,0.63,0.50),0.84)
    var carpet := mat(Color(0.23,0.025,0.035),0.92)

    # Full continuous floors and collision surfaces.
    box(self,Vector3(0,-0.12,hall_center_z),Vector3(15.0,0.24,10.0),Color.WHITE,"hall_floor_collision",true,hall_floor)
    box(self,Vector3(0,-0.12,lib_center_z),Vector3(15.0,0.24,8.0),Color.WHITE,"library_floor_collision",true,mat(Color(0.18,0.055,0.022),0.52))
    # Hall marble slab inlays / border strips.
    for x in [-7.15,-5.0,-2.5,0.0,2.5,5.0,7.15]:
        box(self,Vector3(x,0.012,hall_center_z),Vector3(0.035,0.018,9.75),Color.WHITE,"marble_inlay",false,marble_dark)
    for z in [-0.82,1.0,3.0,5.0,7.0,8.82]:
        box(self,Vector3(0,0.013,z),Vector3(14.7,0.018,0.035),Color.WHITE,"marble_inlay",false,marble_dark)
    add_rug(Vector3(0,0.025,4.35),Vector2(4.2,5.1),Color(0.22,0.025,0.035))
    # Library wood floor with a framed central rug.
    add_rug(Vector3(0,0.035,-5.05),Vector2(5.0,3.7),Color(0.20,0.035,0.025))
    for x in range(-7,8):
        box(self,Vector3(float(x),0.018,lib_center_z),Vector3(0.018,0.025,7.82),Color.WHITE,"parquet_seam",false,mahogany)

    # Perimeter walls. Both rooms share a 3 m first level and 3 m upper level.
    add_trim_wall(Vector3(-7.35,3.0,hall_center_z),Vector3(0.30,6.0,10.0),Color(0.62,0.55,0.43))
    add_trim_wall(Vector3(7.35,3.0,hall_center_z),Vector3(0.30,6.0,10.0),Color(0.62,0.55,0.43))
    add_trim_wall(Vector3(0,3.0,9.0),Vector3(15.0,6.0,0.30),Color(0.62,0.55,0.43))
    # Open central doorway between hall and library; wall segments leave a 3 m opening.
    add_trim_wall(Vector3(-4.70,3.0,-1.0),Vector3(5.60,6.0,0.30),Color(0.62,0.55,0.43))
    add_trim_wall(Vector3(4.70,3.0,-1.0),Vector3(5.60,6.0,0.30),Color(0.62,0.55,0.43))
    add_door(Vector3(0,0,8.78),2.8,2.75,true)
    add_door(Vector3(0,0,-1.18),2.8,2.75,true)

    # Upper walls have a separate cornice band and decorative panels.
    for side in [-1.0,1.0]:
        for i in range(5):
            var z := -0.05 + float(i)*2.0
            _add_wall_panel(Vector3(side*7.17,4.45,z),Vector2(1.25,1.65),PI*0.5 if side < 0 else -PI*0.5)
        for i in range(4):
            var z2 := 0.15+float(i)*2.25
            _add_wall_panel(Vector3(side*7.17,1.85,z2),Vector2(1.20,1.55),PI*0.5 if side < 0 else -PI*0.5)
    for i in range(5):
        var x := -6.0+float(i)*3.0
        _add_wall_panel(Vector3(x,1.9,8.82),Vector2(1.65,1.55),0.0)
        _add_wall_panel(Vector3(x,4.55,8.82),Vector2(1.65,1.65),0.0)
    # Ornate two-level coffered ceiling, kept at 6 m.
    box(self,Vector3(0,6.0,hall_center_z),Vector3(15.0,0.20,10.0),Color.WHITE,"hall_ceiling",false,cream)
    box(self,Vector3(0,6.0,lib_center_z),Vector3(15.0,0.20,8.0),Color.WHITE,"library_ceiling",false,cream)
    for x in [-7.1,-5.0,-2.5,0.0,2.5,5.0,7.1]:
        box(self,Vector3(x,5.86,hall_center_z),Vector3(0.15,0.22,9.8),Color.WHITE,"ceiling_coffer_beam",false,gold)
    for z in [-0.8,1.0,3.0,5.0,7.0,8.8]:
        box(self,Vector3(0,5.86,z),Vector3(14.8,0.22,0.15),Color.WHITE,"ceiling_coffer_beam",false,gold)
    for x in [-7.1,-4.7,-2.35,0.0,2.35,4.7,7.1]:
        box(self,Vector3(x,5.86,lib_center_z),Vector3(0.13,0.22,7.8),Color.WHITE,"library_ceiling_beam",false,mahogany)
    for z in [-8.8,-7.0,-5.0,-3.0,-1.2]:
        box(self,Vector3(0,5.86,z),Vector3(14.8,0.22,0.13),Color.WHITE,"library_ceiling_beam",false,mahogany)

    # Side staircases, each rises exactly 3 m to the gallery; never block the middle of the hall.
    add_stairs(-5.1,7.4,-1.0)
    add_stairs(5.1,7.4,-1.0)
    _add_upper_gallery(-5.1,2.2,2.8,3.0)
    _add_upper_gallery(5.1,2.2,2.8,3.0)
    # Front balustrade / upper gallery edges.
    for side in [-1.0,1.0]:
        box(self,Vector3(side*3.0,3.48,2.2),Vector3(1.55,0.10,0.12),Color.WHITE,"gallery_front_rail",false,gold)
        for i in range(6):
            box(self,Vector3(side*(2.3+float(i)*0.27),3.42,2.2),Vector3(0.055,0.72,0.055),Color.WHITE,"gallery_front_baluster",false,mahogany)

    # Hall furniture: console tables, framed paintings, sconces, gilded accents and chandeliers.
    for x in [-6.65,6.65]:
        for z in [0.2,4.3,7.7]:
            add_console(Vector3(x,0,z))
            add_wall_sconce(Vector3(x*0.99,2.25,z+0.65),PI*0.5 if x<0 else -PI*0.5)
    for x in [-5.9,-3.0,3.0,5.9]:
        add_portrait(Vector3(x,2.12,8.80),Vector2(0.88,1.22),0.0)
    for x in [-6.0,-2.0,2.0,6.0]:
        add_portrait(Vector3(x,4.55,8.80),Vector2(0.90,1.25),0.0)
    add_chandelier(Vector3(0,4.15,4.3))
    add_chandelier(Vector3(-4.6,4.35,1.1))
    add_chandelier(Vector3(4.6,4.35,1.1))
    # Decorative center table / flower arrangement silhouette.
    cyl(self,Vector3(0,0.52,4.35),0.70,0.12,Color.WHITE,true,mahogany)
    cyl(self,Vector3(0,0.28,4.35),0.13,0.42,Color.WHITE,true,gold)
    for i in range(9):
        var a := TAU*float(i)/9.0
        cyl(self,Vector3(cos(a)*0.20,0.82+float(i%3)*0.035,4.35+sin(a)*0.20),0.09,0.32,Color(0.74,0.78,0.61),false,mat(Color(0.74,0.78,0.61),0.75))

    # Library shell and continuous book-lined walls (15 x 8 m).
    add_trim_wall(Vector3(-7.35,3.0,lib_center_z),Vector3(0.30,6.0,8.0),Color(0.31,0.20,0.13))
    add_trim_wall(Vector3(7.35,3.0,lib_center_z),Vector3(0.30,6.0,8.0),Color(0.31,0.20,0.13))
    add_trim_wall(Vector3(0,3.0,-9.0),Vector3(15.0,6.0,0.30),Color(0.31,0.20,0.13))
    # Rear wall bookcases stop short of the centered double door.
    add_bookshelf_wall(-8.80,-4.55,5.3,5.65)
    add_bookshelf_wall(-8.80,4.55,5.3,5.65)
    # Long shelves on both side walls, lower and upper rows with visible books.
    for side in [-1.0,1.0]:
        for z in [-7.45,-5.1,-2.8]:
            # A tall window interrupts the left-wall shelves at the middle bay.
            if side < 0.0 and abs(z + 5.1) < 0.1:
                continue
            add_bookshelf_side(side*7.14,z,0.40,2.15,5.65)
            # Extra shelf ledges and many visible book spines across each bay.
            for y in [0.55,1.25,1.95,2.65,3.35,4.05,4.75,5.35]:
                box(self,Vector3(side*6.89,y,z),Vector3(0.16,0.07,1.95),Color.WHITE,"library_shelf_lip",false,mahogany)
                for i in range(8):
                    var book_h := 0.35+float((i*3+int(abs(z))+int(y*10))%5)*0.055
                    var book_colors: Array[Color] = [Color(0.22,0.035,0.025),Color(0.10,0.15,0.10),Color(0.35,0.19,0.055),Color(0.14,0.045,0.12)]
                    var book_color: Color = book_colors[i%4]
                    box(self,Vector3(side*6.76,y+book_h*0.5,z-0.82+float(i)*0.22),Vector3(0.20,book_h,0.14),Color.WHITE,"library_book",false,mat(book_color,0.72))
    # U-shaped upper gallery: walkable side wings and rear balcony, with an open central void.
    box(self,Vector3(-5.65,3.02,-5.0),Vector3(2.35,0.16,6.45),Color.WHITE,"library_gallery_left",true,mahogany)
    box(self,Vector3(5.65,3.02,-5.0),Vector3(2.35,0.16,6.45),Color.WHITE,"library_gallery_right",true,mahogany)
    box(self,Vector3(0,3.02,-7.95),Vector3(12.0,0.16,1.15),Color.WHITE,"library_gallery_rear",true,mahogany)
    for side in [-1.0,1.0]:
        var rail_x: float = side*4.45
        box(self,Vector3(rail_x,3.48,-5.0),Vector3(0.10,0.90,6.15),Color.WHITE,"library_gallery_rail",false,mahogany)
        box(self,Vector3(rail_x,3.94,-5.0),Vector3(0.16,0.12,6.25),Color.WHITE,"library_gallery_handrail",false,gold)
        for i in range(15):
            var rz: float = -8.0+float(i)*0.43
            box(self,Vector3(rail_x,3.43,rz),Vector3(0.055,0.72,0.055),Color.WHITE,"library_gallery_baluster",false,mahogany)
    box(self,Vector3(0,3.48,-7.30),Vector3(11.8,0.90,0.10),Color.WHITE,"library_gallery_rear_rail",false,mahogany)
    box(self,Vector3(0,3.94,-7.30),Vector3(12.0,0.12,0.16),Color.WHITE,"library_gallery_rear_handrail",false,gold)
    add_ladder(Vector3(-5.9,0.1,-5.0))
    add_ladder(Vector3(5.9,0.1,-5.0))
    # Library fireplace and mantel on rear wall; framed portrait above.
    box(self,Vector3(0,1.0,-8.72),Vector3(2.45,1.95,0.36),Color.WHITE,"fireplace_surround",false,mat(Color(0.20,0.065,0.025),0.48))
    box(self,Vector3(0,0.75,-8.48),Vector3(1.35,1.25,0.16),Color.WHITE,"fireplace_opening",false,mat(Color(0.018,0.008,0.004),0.95))
    box(self,Vector3(0,2.08,-8.47),Vector3(2.85,0.16,0.52),Color.WHITE,"fireplace_mantel",false,gold)
    add_portrait(Vector3(0,3.30,-8.78),Vector2(1.15,1.45),0.0)
    # Tall window on the left library wall, as in the visual reference.
    _add_window(Vector3(-7.14,0.25,-5.1),1.65,2.2,PI*0.5)
    for x in [-6.8,6.8]:
        for z in [-7.0,-4.9,-2.8]:
            add_wall_sconce(Vector3(x,2.45,z),PI*0.5 if x<0 else -PI*0.5)
    add_chandelier(Vector3(0,4.25,-5.0))
    # Reading table, leather seating blocks, side desks, globe and lamps.
    box(self,Vector3(0,0.66,-5.15),Vector3(2.0,0.14,1.05),Color.WHITE,"library_table",true,mahogany)
    for x in [-0.78,0.78]:
        box(self,Vector3(x,0.33,-5.15),Vector3(0.13,0.66,0.13),Color.WHITE,"library_table_leg",true,mahogany)
    for x in [-2.25,2.25]:
        box(self,Vector3(x,0.42,-4.9),Vector3(1.15,0.72,0.95),Color.WHITE,"leather_armchair",true,mat(Color(0.15,0.035,0.025),0.74))
        box(self,Vector3(x,0.85,-5.25),Vector3(1.15,0.85,0.22),Color.WHITE,"armchair_back",true,mat(Color(0.15,0.035,0.025),0.74))
    box(self,Vector3(-4.7,0.55,-2.1),Vector3(1.8,0.12,0.65),Color.WHITE,"reading_desk",true,mahogany)
    cyl(self,Vector3(4.8,0.48,-2.3),0.25,0.8,Color.WHITE,false,mahogany)
    cyl(self,Vector3(4.8,0.96,-2.3),0.38,0.05,Color.WHITE,false,mat(Color(0.12,0.20,0.18),0.38))

    # A consistent 3 m upper floor-to-ceiling height throughout the mansion.
    # The open central hall remains double-height; side galleries are at exactly y=3 m.

func _ready() -> void:
    AudioManager.play_music("mansion")
    decor()
    var enemy = preload("res://scenes/enemy.tscn").instantiate()
    enemy.position = Vector3(4.0,0.2,-7.35)
    add_child(enemy)
    survivor = preload("res://scenes/survivor.tscn").instantiate()
    survivor.add_to_group("survivor")
    survivor.position = Vector3(-4.8,0.2,-7.2)
    add_child(survivor)
    survivor.rescued.connect(_on_rescued)
    boss = preload("res://scenes/boss.tscn").instantiate()
    boss.add_to_group("enemy")
    boss.position = Vector3(0,0.2,-6.2)
    add_child(boss)
    boss.visible = false
    boss.process_mode = Node.PROCESS_MODE_DISABLED
    boss.defeated.connect(_on_boss_defeated)
    cutscene = preload("res://scripts/cutscene_manager.gd").new()
    add_child(cutscene)
    call_deferred("_start_intro")

func _start_intro() -> void:
    cutscene.setup(self,$Player,$HUD)
    await cutscene.intro()

func _on_rescued() -> void:
    GameState.flags["boss_unlocked"] = true
    GameState.save_game()
    boss.visible = true
    boss.process_mode = Node.PROCESS_MODE_INHERIT
    show_message("Лекарство передано. Архив открыт.")

func _on_boss_defeated() -> void:
    completed = true
    call_deferred("_final_cutscene")

func _final_cutscene() -> void:
    await cutscene.final_scene()

func show_message(text_value: String) -> void:
    if has_node("HUD") and $HUD.has_method("show_message"):
        $HUD.show_message(text_value)
    elif message_label:
        message_label.text = text_value

func try_interact(player) -> void:
    if survivor and not survivor.used and player.global_position.distance_to(survivor.global_position) < 2.8:
        show_message(survivor.interact(player))
        return
    if boss and not GameState.flags.get("boss_unlocked",false) and player.global_position.distance_to(boss.global_position) < 4:
        show_message("Сначала найдите выжившего и дайте ему лекарство.")

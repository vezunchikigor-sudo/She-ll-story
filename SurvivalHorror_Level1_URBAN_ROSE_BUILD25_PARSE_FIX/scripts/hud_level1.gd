extends CanvasLayer

@onready var player: CharacterBody3D = get_parent().get_node("Player")
@onready var level: Node3D = get_parent()
@onready var ui: Control = $UI
@onready var hpbar: ProgressBar = $UI/HPBar
@onready var hpglow: ColorRect = $UI/HPGlow
@onready var status: Label = $UI/Status

var inventory_panel: Panel
var weapon_panel: Panel
var inventory_open := false
var message_timer := 0.0
var touch_actions: Dictionary = {}
var minimap: LevelMiniMap

func _ready() -> void:
    level.message_label = status
    _build_hud()
    status.visible = false

func _process(delta: float) -> void:
    hpbar.value = player.hp
    hpglow.visible = player.hp <= 20
    if message_timer > 0.0:
        message_timer -= delta
        if message_timer <= 0.0:
            status.visible = false
    if player and player.combat:
        _update_hud_values()

func show_message(text: String, seconds: float = 2.8) -> void:
    status.text = text
    status.visible = true
    message_timer = seconds

func _make_style(alpha: float = 0.62) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color(0.025, 0.025, 0.025, alpha)
    s.border_width_left = 2
    s.border_width_top = 2
    s.border_width_right = 2
    s.border_width_bottom = 2
    s.border_color = Color(1, 1, 1, 0.30)
    s.corner_radius_top_left = 70
    s.corner_radius_top_right = 70
    s.corner_radius_bottom_left = 70
    s.corner_radius_bottom_right = 70
    return s

func _icon_button(parent: Control, name: String, texture_path: String, ax: float, ay: float, aw: float, ah: float) -> TextureButton:
    var b := TextureButton.new()
    b.name = name
    b.anchor_left = ax; b.anchor_top = ay; b.anchor_right = ax + aw; b.anchor_bottom = ay + ah
    b.offset_left = 0; b.offset_top = 0; b.offset_right = 0; b.offset_bottom = 0
    b.grow_horizontal = Control.GROW_DIRECTION_BOTH; b.grow_vertical = Control.GROW_DIRECTION_BOTH
    var icon_texture: Texture2D = load(texture_path) as Texture2D
    b.texture_normal = icon_texture
    b.texture_hover = b.texture_normal
    b.texture_pressed = b.texture_normal
    b.ignore_texture_size = true
    b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
    b.mouse_filter = Control.MOUSE_FILTER_STOP
    b.focus_mode = Control.FOCUS_NONE
    b.z_index = 220
    b.tooltip_text = ""
    parent.add_child(b)
    b.button_down.connect(func(): _press_icon(b))
    b.button_up.connect(func(): _release_icon(b))
    return b

func _press_icon(b: TextureButton) -> void:
    b.modulate = Color(0.72, 0.72, 0.72, 1.0)
    b.scale = Vector2(0.94, 0.94)
    b.pivot_offset = b.size * 0.5

func _release_icon(b: TextureButton) -> void:
    b.modulate = Color.WHITE
    b.scale = Vector2.ONE

func _build_hud() -> void:
    for child in ui.get_children():
        if child == hpbar or child == hpglow or child == status:
            continue
        child.queue_free()

    var top := Control.new()
    top.name = "TopInfo"
    top.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    top.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(top)

    var ammo_icon := Label.new(); ammo_icon.position = Vector2(28, 16); ammo_icon.text = "▰"; ammo_icon.add_theme_font_size_override("font_size", 26); top.add_child(ammo_icon)
    var ammo := Label.new(); ammo.name = "AmmoReserve"; ammo.position = Vector2(62, 16); ammo.add_theme_font_size_override("font_size", 26); top.add_child(ammo)
    var small_icon := Label.new(); small_icon.position = Vector2(155, 16); small_icon.text = "+"; small_icon.add_theme_font_size_override("font_size", 25); top.add_child(small_icon)
    var small := Label.new(); small.name = "SmallMed"; small.position = Vector2(180, 16); small.add_theme_font_size_override("font_size", 25); top.add_child(small)
    var large_icon := Label.new(); large_icon.position = Vector2(240, 16); large_icon.text = "□"; large_icon.add_theme_font_size_override("font_size", 25); top.add_child(large_icon)
    var large := Label.new(); large.name = "LargeMed"; large.position = Vector2(268, 16); large.add_theme_font_size_override("font_size", 25); top.add_child(large)

    var joy := Control.new()
    joy.name = "Joystick"
    joy.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    joy.anchor_left = 0.02; joy.anchor_top = 0.62; joy.anchor_right = 0.25; joy.anchor_bottom = 0.98
    joy.offset_left = 0; joy.offset_top = 0; joy.offset_right = 0; joy.offset_bottom = 0
    joy.grow_horizontal = Control.GROW_DIRECTION_BOTH; joy.grow_vertical = Control.GROW_DIRECTION_BOTH
    joy.mouse_filter = Control.MOUSE_FILTER_STOP
    joy.set_script(load("res://scripts/mobile_joystick.gd"))
    ui.add_child(joy)
    joy.vector_changed.connect(player.set_mobile_move)
    joy.sprint_changed.connect(player.set_mobile_sprint)
    joy.block_changed.connect(player.set_mobile_block)

    # Dedicated camera swipe surface on the right half. Buttons are above it in the scene tree.
    var look := Control.new()
    look.name = "LookZone"
    look.anchor_left = 0.42; look.anchor_top = 0.05; look.anchor_right = 1.0; look.anchor_bottom = 0.94
    look.offset_left = 0; look.offset_top = 0; look.offset_right = 0; look.offset_bottom = 0
    look.grow_horizontal = Control.GROW_DIRECTION_BOTH; look.grow_vertical = Control.GROW_DIRECTION_BOTH
    look.mouse_filter = Control.MOUSE_FILTER_PASS
    look.z_index = 0
    look.set_script(load("res://scripts/look_zone.gd"))
    ui.add_child(look)

    var buttons := Control.new()
    buttons.name = "ActionButtons"
    buttons.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    buttons.mouse_filter = Control.MOUSE_FILTER_STOP
    buttons.z_index = 1000
    ui.add_child(buttons)

    # Exact button centers measured from Gameplay.jpeg (2816x1584).
    # The buttons are direct children of a STOP parent so the camera look surface cannot steal touches.
    var use := _icon_button(buttons, "Use", "res://art/ui/interact.png", 0.772, 0.846, 0.058, 0.104)
    use.button_down.connect(func(): AudioManager.ui_click(); level.try_interact(player))
    var reload := _icon_button(buttons, "Reload", "res://art/ui/reload.png", 0.632, 0.846, 0.058, 0.104)
    reload.button_down.connect(func(): AudioManager.ui_click(); player.mobile_reload())
    var aim := _icon_button(buttons, "Aim", "res://art/ui/aim.png", 0.701, 0.846, 0.058, 0.104)
    aim.button_down.connect(func(): AudioManager.ui_click(); player.mobile_toggle_aim())
    var fire := _icon_button(buttons, "Fire", "res://art/ui/fire.png", 0.020, 0.485, 0.058, 0.104)
    fire.button_down.connect(func(): player.mobile_fire_down())
    fire.button_up.connect(func(): player.mobile_fire_up())
    var crouch := _icon_button(buttons, "Crouch", "res://art/ui/crouch.png", 0.841, 0.846, 0.058, 0.104)
    crouch.button_down.connect(func(): AudioManager.ui_click(); player.toggle_crouch())
    var bag := _icon_button(buttons, "Inventory", "res://art/ui/inventory.png", 0.914, 0.846, 0.058, 0.104)
    bag.button_down.connect(func(): AudioManager.ui_click(); _toggle_inventory())

    inventory_panel = Panel.new()
    inventory_panel.name = "InventoryPanel"
    inventory_panel.anchor_left = 0.48; inventory_panel.anchor_top = 0.22; inventory_panel.anchor_right = 0.82; inventory_panel.anchor_bottom = 0.78
    inventory_panel.offset_left = 0; inventory_panel.offset_top = 0; inventory_panel.offset_right = 0; inventory_panel.offset_bottom = 0
    inventory_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH; inventory_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
    inventory_panel.visible = false
    inventory_panel.z_index = 200
    inventory_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    inventory_panel.add_theme_stylebox_override("panel", _panel_style())
    ui.add_child(inventory_panel)
    _populate_inventory()

    weapon_panel = Panel.new()
    weapon_panel.name = "WeaponPanel"
    weapon_panel.anchor_left = 0.82; weapon_panel.anchor_top = 0.22; weapon_panel.anchor_right = 0.98; weapon_panel.anchor_bottom = 0.78
    weapon_panel.offset_left = 0; weapon_panel.offset_top = 0; weapon_panel.offset_right = 0; weapon_panel.offset_bottom = 0
    weapon_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH; weapon_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
    weapon_panel.visible = false
    weapon_panel.z_index = 201
    weapon_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    weapon_panel.add_theme_stylebox_override("panel", _panel_style())
    ui.add_child(weapon_panel)
    _populate_weapons()

    var hp_title := Label.new()
    hp_title.anchor_left = 0.02; hp_title.anchor_top = 0.94; hp_title.anchor_right = 0.08; hp_title.anchor_bottom = 0.99
    hp_title.offset_left = 0; hp_title.offset_top = 0; hp_title.offset_right = 0; hp_title.offset_bottom = 0
    hp_title.text = "HP"
    hp_title.add_theme_font_size_override("font_size", 16)
    ui.add_child(hp_title)

    minimap = LevelMiniMap.new()
    minimap.name = "LevelMiniMap"
    minimap.anchor_left = 0.72; minimap.anchor_top = 0.01
    minimap.anchor_right = 0.995; minimap.anchor_bottom = 0.30
    minimap.offset_left = 0; minimap.offset_top = 0; minimap.offset_right = 0; minimap.offset_bottom = 0
    minimap.grow_horizontal = Control.GROW_DIRECTION_BOTH
    minimap.grow_vertical = Control.GROW_DIRECTION_BOTH
    minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
    minimap.z_index = 160
    ui.add_child(minimap)
    minimap.setup(level, player)

func _panel_style() -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color(0.015, 0.015, 0.015, 0.90)
    s.border_width_left = 2
    s.border_width_top = 2
    s.border_width_right = 2
    s.border_width_bottom = 2
    s.border_color = Color(1, 1, 1, 0.32)
    s.corner_radius_top_left = 16
    s.corner_radius_top_right = 16
    s.corner_radius_bottom_left = 16
    s.corner_radius_bottom_right = 16
    return s

func _populate_inventory() -> void:
    var title := Label.new()
    title.text = "ИНВЕНТАРЬ"
    title.position = Vector2(20, 12)
    title.add_theme_font_size_override("font_size", 22)
    inventory_panel.add_child(title)
    var names := ["Нож", "Лекарство", "Малая аптечка", "Аптечка", "USP-S патроны", "Дробовик патроны", "Uzi патроны", "Ракетница патроны", "Гранаты"]
    for i in 9:
        var cell := Button.new()
        cell.text = names[i]
        cell.position = Vector2(18 + (i % 3) * 162, 58 + (i / 3) * 82)
        cell.size = Vector2(150, 70)
        cell.focus_mode = Control.FOCUS_NONE
        cell.add_theme_font_size_override("font_size", 14)
        cell.add_theme_stylebox_override("normal", _make_style(0.42))
        cell.add_theme_stylebox_override("pressed", _make_style(0.70))
        cell.pressed.connect(Callable(self, "_inventory_use").bind(i))
        cell.button_down.connect(AudioManager.ui_click)
        inventory_panel.add_child(cell)

func _populate_weapons() -> void:
    var title := Label.new()
    title.text = "ОРУЖИЕ"
    title.position = Vector2(18, 12)
    title.add_theme_font_size_override("font_size", 22)
    weapon_panel.add_child(title)
    var names := ["USP-S", "UZI", "SHOTGUN", "ROCKET"]
    var values := ["Pistol", "Uzi", "Shotgun", "RocketLauncher"]
    for i in 4:
        var b := Button.new()
        b.text = names[i]
        b.position = Vector2(18, 55 + i * 65)
        b.size = Vector2(264, 55)
        b.focus_mode = Control.FOCUS_NONE
        b.add_theme_stylebox_override("normal", _make_style(0.42))
        b.add_theme_stylebox_override("pressed", _make_style(0.70))
        var weapon_name: String = values[i]
        b.pressed.connect(Callable(self, "_inventory_select_weapon").bind(weapon_name))
        weapon_panel.add_child(b)

func _inventory_select_weapon(weapon_name: String) -> void:
    AudioManager.ui_click()
    player.mobile_equip(weapon_name)
    _toggle_inventory()

func _toggle_inventory() -> void:
    inventory_open = not inventory_open
    inventory_panel.visible = inventory_open
    weapon_panel.visible = inventory_open

func _inventory_use(index: int) -> void:
    match index:
        0:
            player.combat.equip("Knife")
            _toggle_inventory()
        1:
            if GameState.survivor_medicine > 0:
                show_message("Лекарство предназначено выжившему.")
        2:
            player.heal_small()
            _toggle_inventory()
        3:
            player.heal_large()
            _toggle_inventory()
        4, 5, 6, 7, 8:
            show_message("Боеприпасы используются автоматически при перезарядке.")

func _update_hud_values() -> void:
    var top := ui.get_node_or_null("TopInfo")
    if top == null:
        return
    top.get_node("AmmoReserve").text = "%03d" % player.combat.reserve
    top.get_node("SmallMed").text = str(GameState.small_medkits)
    top.get_node("LargeMed").text = str(GameState.large_medkits)

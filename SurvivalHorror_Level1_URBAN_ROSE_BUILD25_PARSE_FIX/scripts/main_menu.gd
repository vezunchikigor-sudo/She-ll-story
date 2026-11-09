extends Control

var settings_panel: Panel
var info_label: Label
var busy := false
var press_overlays: Dictionary = {}

func _ready() -> void:
    $Background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $Info.mouse_filter = Control.MOUSE_FILTER_IGNORE
    info_label = $Info
    _setup_button($NewGame)
    _setup_button($Continue)
    _setup_button($Settings)
    call_deferred("_align_menu_buttons")
    $NewGame.pressed.connect(_new_game)
    $Continue.pressed.connect(_continue_game)
    $Settings.pressed.connect(_settings)
    $NewGame.button_down.connect(func(): _press_visual($NewGame))
    $NewGame.button_up.connect(func(): _release_visual($NewGame))
    $Continue.button_down.connect(func(): _press_visual($Continue))
    $Continue.button_up.connect(func(): _release_visual($Continue))
    $Settings.button_down.connect(func(): _press_visual($Settings))
    $Settings.button_up.connect(func(): _release_visual($Settings))
    AudioManager.play_music("menu")

func _align_menu_buttons() -> void:
    # Align the invisible touch rectangles to the real buttons baked into main_menu.jpg.
    var rects := [
        Rect2(0.413, 0.717, 0.167, 0.064),
        Rect2(0.413, 0.781, 0.167, 0.064),
        Rect2(0.413, 0.845, 0.167, 0.063)
    ]
    var names := [$NewGame, $Continue, $Settings]
    var viewport_size: Vector2 = get_viewport_rect().size
    var image_size := Vector2(2816.0, 1584.0)
    var scale_factor: float = min(viewport_size.x / image_size.x, viewport_size.y / image_size.y)
    var shown_size: Vector2 = image_size * scale_factor
    var image_origin := (viewport_size - shown_size) * 0.5
    for i in rects.size():
        var r: Rect2 = rects[i]
        var b: Button = names[i]
        b.anchor_left = 0.0; b.anchor_top = 0.0; b.anchor_right = 0.0; b.anchor_bottom = 0.0
        b.position = image_origin + Vector2(r.position.x * shown_size.x, r.position.y * shown_size.y)
        b.size = Vector2(r.size.x * shown_size.x, r.size.y * shown_size.y)

func _setup_button(b: Button) -> void:
    b.mouse_filter = Control.MOUSE_FILTER_STOP
    b.focus_mode = Control.FOCUS_NONE
    b.z_index = 200
    b.flat = true
    b.custom_minimum_size = Vector2(1, 1)
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color(0, 0, 0, 0)
    normal.border_color = Color(0, 0, 0, 0)
    normal.set_border_width_all(0)
    var hover := normal.duplicate()
    var pressed := normal.duplicate()
    b.add_theme_stylebox_override("normal", normal)
    b.add_theme_stylebox_override("hover", hover)
    b.add_theme_stylebox_override("pressed", pressed)
    b.add_theme_stylebox_override("focus", normal)
    b.add_theme_color_override("font_color", Color(0, 0, 0, 0))
    b.add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
    b.add_theme_color_override("font_pressed_color", Color(1.0, 0.82, 0.45, 1.0))
    b.add_theme_color_override("font_focus_color", Color(0, 0, 0, 0))
    b.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.01, 0.9))
    b.add_theme_constant_override("outline_size", 5)
    b.add_theme_font_size_override("font_size", 30)
    # The menu artwork already contains the button labels. The Button nodes are
    # invisible touch targets only; never draw a second text label over the artwork.
    b.text = ""

func _press_visual(b: Button) -> void:
    # The labels are baked into the menu artwork. Give the artwork itself a
    # physical-looking press: a subtle dark inset, never another text label.
    var overlay: ColorRect = press_overlays.get(b) as ColorRect
    if overlay == null:
        overlay = ColorRect.new()
        overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
        overlay.color = Color(0.0, 0.0, 0.0, 0.24)
        overlay.z_index = 150
        add_child(overlay)
        press_overlays[b] = overlay
    overlay.position = b.position + Vector2(0, 2)
    overlay.size = b.size
    overlay.visible = true
    var tween := create_tween()
    tween.tween_property(overlay, "color:a", 0.32, 0.05)

func _release_visual(b: Button) -> void:
    var overlay: ColorRect = press_overlays.get(b) as ColorRect
    if overlay == null:
        return
    var tween := create_tween()
    tween.tween_property(overlay, "color:a", 0.0, 0.10)
    tween.tween_callback(func(): overlay.visible = false)

func _new_game() -> void:
    if busy:
        return
    busy = true
    $NewGame.disabled = true
    GameState.hp = 100
    GameState.small_medkits = 4
    GameState.large_medkits = 1
    GameState.survivor_medicine = 1
    GameState.flags.clear()
    GameState.save_game()
    get_tree().change_scene_to_file("res://scenes/mansion_floor1.tscn")

func _continue_game() -> void:
    if busy:
        return
    busy = true
    if GameState.has_method("load_game"):
        GameState.load_game()
    get_tree().change_scene_to_file("res://scenes/mansion_floor1.tscn")

func _settings() -> void:
    if settings_panel != null:
        return
    settings_panel = Panel.new()
    settings_panel.name = "SettingsPanel"
    settings_panel.anchor_left = 0.08
    settings_panel.anchor_top = 0.16
    settings_panel.anchor_right = 0.92
    settings_panel.anchor_bottom = 0.84
    settings_panel.offset_left = 0
    settings_panel.offset_top = 0
    settings_panel.offset_right = 0
    settings_panel.offset_bottom = 0
    settings_panel.z_index = 100
    settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color(0.015, 0.012, 0.01, 0.96)
    bg.border_width_left = 3; bg.border_width_top = 3; bg.border_width_right = 3; bg.border_width_bottom = 3
    bg.border_color = Color(0.72, 0.54, 0.30, 0.85)
    bg.corner_radius_top_left = 18; bg.corner_radius_top_right = 18; bg.corner_radius_bottom_left = 18; bg.corner_radius_bottom_right = 18
    settings_panel.add_theme_stylebox_override("panel", bg)
    add_child(settings_panel)

    var title := Label.new()
    title.text = "НАСТРОЙКИ"
    title.anchor_left = 0.06; title.anchor_top = 0.05; title.anchor_right = 0.94; title.anchor_bottom = 0.16
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 30)
    settings_panel.add_child(title)

    var lang := Button.new()
    lang.text = "Язык: Русский / English"
    lang.anchor_left = 0.06; lang.anchor_top = 0.20; lang.anchor_right = 0.94; lang.anchor_bottom = 0.34
    lang.offset_left = 0; lang.offset_top = 0; lang.offset_right = 0; lang.offset_bottom = 0
    lang.focus_mode = Control.FOCUS_NONE
    lang.pressed.connect(func(): GameState.language = "English" if GameState.language == "Russian" else "Russian"; lang.text = "Язык: Русский / English  [" + GameState.language + "]"; GameState.save_game())
    settings_panel.add_child(lang)

    var graphics := Button.new()
    graphics.text = "Графика: " + str(GameState.graphics_quality)
    graphics.anchor_left = 0.06; graphics.anchor_top = 0.38; graphics.anchor_right = 0.94; graphics.anchor_bottom = 0.52
    graphics.offset_left = 0; graphics.offset_top = 0; graphics.offset_right = 0; graphics.offset_bottom = 0
    graphics.focus_mode = Control.FOCUS_NONE
    graphics.pressed.connect(func():
        var modes := ["High", "Medium", "Low"]
        var idx := modes.find(GameState.graphics_quality)
        GameState.graphics_quality = modes[(idx + 1) % modes.size()]
        graphics.text = "Графика: " + GameState.graphics_quality
        GameState.save_game())
    settings_panel.add_child(graphics)

    var sens := Label.new()
    sens.text = "Чувствительность камеры: %.3f" % GameState.camera_sensitivity
    sens.anchor_left = 0.06; sens.anchor_top = 0.56; sens.anchor_right = 0.94; sens.anchor_bottom = 0.66
    sens.offset_left = 0; sens.offset_top = 0; sens.offset_right = 0; sens.offset_bottom = 0
    settings_panel.add_child(sens)

    var note := Label.new()
    note.text = "Позиции кнопок управления — подготовлены для следующего этапа."
    note.anchor_left = 0.06; note.anchor_top = 0.66; note.anchor_right = 0.94; note.anchor_bottom = 0.78
    note.offset_left = 0; note.offset_top = 0; note.offset_right = 0; note.offset_bottom = 0
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    settings_panel.add_child(note)

    var close := Button.new()
    close.text = "ЗАКРЫТЬ"
    close.anchor_left = 0.28; close.anchor_top = 0.80; close.anchor_right = 0.72; close.anchor_bottom = 0.94
    close.offset_left = 0; close.offset_top = 0; close.offset_right = 0; close.offset_bottom = 0
    close.focus_mode = Control.FOCUS_NONE
    close.pressed.connect(func(): settings_panel.queue_free(); settings_panel = null)
    settings_panel.add_child(close)

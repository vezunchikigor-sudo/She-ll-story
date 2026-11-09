extends Node

var level: Node3D
var player: CharacterBody3D
var hud: CanvasLayer
var overlay: CanvasLayer
var fade: ColorRect
var video_backdrop: ColorRect
var video_player: VideoStreamPlayer
var title: Label
var subtitle: Label
var active := false
var skip_layer: Control
var finishing := false

func setup(p_level: Node3D, p_player: CharacterBody3D, p_hud: CanvasLayer) -> void:
    level = p_level
    player = p_player
    hud = p_hud
    _build_overlay()

func _build_overlay() -> void:
    if overlay:
        return
    overlay = CanvasLayer.new()
    overlay.layer = 100
    add_child(overlay)

    # Solid black letterbox layer: the 3D mansion must never be visible beside the portrait cinematic.
    video_backdrop = ColorRect.new()
    video_backdrop.name = "BlackVideoBackdrop"
    video_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    video_backdrop.color = Color.BLACK
    video_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    video_backdrop.z_index = 5
    overlay.add_child(video_backdrop)

    video_player = VideoStreamPlayer.new()
    video_player.name = "IntroVideo"
    video_player.expand = true
    video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
    video_player.visible = false
    video_player.z_index = 10
    var stream: Resource = ResourceLoader.load("res://video/intro_cutscene.ogv")
    if stream is VideoStream:
        video_player.stream = stream as VideoStream
    overlay.add_child(video_player)

    # Invisible full-screen touch surface: tapping anywhere skips the intro.
    skip_layer = Control.new()
    skip_layer.name = "SkipIntroTouch"
    skip_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    skip_layer.mouse_filter = Control.MOUSE_FILTER_STOP
    skip_layer.z_index = 30
    skip_layer.gui_input.connect(_on_intro_input)
    overlay.add_child(skip_layer)

    fade = ColorRect.new()
    fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fade.color = Color(0, 0, 0, 1)
    fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fade.z_index = 20
    overlay.add_child(fade)

    title = Label.new()
    title.position = Vector2(0, 430)
    title.size = Vector2(1920, 70)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 46)
    title.modulate.a = 0.0
    overlay.add_child(title)
    subtitle = Label.new()
    subtitle.position = Vector2(0, 505)
    subtitle.size = Vector2(1920, 55)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 24)
    subtitle.modulate.a = 0.0
    overlay.add_child(subtitle)

func _fit_portrait_video() -> void:
    if video_player == null:
        return
    var vp := get_viewport().get_visible_rect().size
    # Keep the cinematic at true 9:16 instead of stretching it to the game's viewport.
    var width: float = min(vp.x, vp.y * 9.0 / 16.0)
    var height: float = width * 16.0 / 9.0
    video_player.position = (vp - Vector2(width, height)) * 0.5
    video_player.size = Vector2(width, height)

func _on_intro_input(event: InputEvent) -> void:
    if not active or finishing:
        return
    if event is InputEventScreenTouch and event.pressed:
        _skip_intro()
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _skip_intro()

func _skip_intro() -> void:
    if not active or finishing:
        return
    finishing = true
    if video_player:
        video_player.stop()

func _fade_to(alpha: float, duration: float) -> void:
    var tween := create_tween()
    tween.tween_property(fade, "color:a", alpha, duration)
    await tween.finished

func _text_in(main_text: String, sub_text: String) -> void:
    title.text = main_text
    subtitle.text = sub_text
    title.modulate.a = 0.0
    subtitle.modulate.a = 0.0
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(title, "modulate:a", 1.0, 0.45)
    tween.tween_property(subtitle, "modulate:a", 1.0, 0.45)
    await tween.finished

func _text_out() -> void:
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(title, "modulate:a", 0.0, 0.35)
    tween.tween_property(subtitle, "modulate:a", 0.0, 0.35)
    await tween.finished

func intro() -> void:
    if active:
        return
    active = true
    finishing = false
    if player:
        player.set_physics_process(false)
        player.camera_rig.set_cinematic(true)
        player.camera_rig.distance = 3.05
        player.camera_rig.height = 1.66
        player.camera_rig.shoulder = 0.02
        player.camera_rig.normal_fov = 53.0
        player.camera_rig.yaw = 0.0
        player.camera_rig.pitch = -0.08
        # The cinematic finishes behind the character with the knife in the right hand.
        player.position = Vector3(0.0, 0.0, 8.0)
        player.rotation.y = 0.0
        if player.combat:
            player.mobile_equip("Knife")
    if hud:
        hud.visible = false

    video_backdrop.visible = true
    skip_layer.visible = true
    skip_layer.mouse_filter = Control.MOUSE_FILTER_STOP
    fade.visible = true
    fade.color.a = 1.0
    title.modulate.a = 0.0
    subtitle.modulate.a = 0.0

    if video_player != null and video_player.stream != null:
        _fit_portrait_video()
        video_player.visible = true
        video_player.modulate.a = 1.0
        fade.color.a = 0.0
        video_player.play()
        while video_player.is_playing() and not finishing:
            await get_tree().process_frame
        if not finishing:
            finishing = true
        await _finish_intro()
        return

    await _fade_to(0.25, 0.8)
    await _text_in("ОСОБНЯК", "Первый этаж • Найдите выжившего")
    await get_tree().create_timer(1.1).timeout
    await _text_out()
    await _fade_to(0.0, 0.9)
    await _finish_intro()

func _finish_intro() -> void:
    if video_player:
        # Short fade so the live game takes over without a hard cut.
        var crossfade := create_tween()
        crossfade.tween_property(video_player, "modulate:a", 0.0, 0.28)
        await crossfade.finished
        video_player.stop()
        video_player.visible = false
    # Remove the cinematic black backdrop completely before gameplay becomes visible.
    # The backdrop must never remain over the live 3D scene.
    if video_backdrop:
        video_backdrop.visible = false
    if skip_layer:
        skip_layer.visible = false
        skip_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if fade:
        fade.color.a = 0.0
        fade.visible = false
    if hud:
        hud.visible = true
    if player:
        # Keep the live camera at the same composition as the final cinematic frame.
        # Camera control is unlocked immediately, but we do not snap back to the old
        # wide framing on the first gameplay frame.
        player.camera_rig.distance = 3.05
        player.camera_rig.height = 1.66
        player.camera_rig.shoulder = 0.02
        player.camera_rig.normal_fov = 53.0
        player.camera_rig.set_cinematic(false)
        player.set_physics_process(true)
    finishing = false
    active = false


func boss_intro() -> void:
    if active:
        return
    active = true
    if player:
        player.set_physics_process(false)
        player.camera_rig.set_cinematic(true)
    if hud:
        hud.visible = false
    fade.color.a = 0.0
    await _fade_to(0.55, 0.55)
    await _text_in("ДВЕРЬ ОТКРЫТА", "Внутри тебя уже ждут…")
    await get_tree().create_timer(1.8).timeout
    await _text_out()
    await _fade_to(0.0, 0.6)
    if hud:
        hud.visible = true
    if player:
        player.camera_rig.set_cinematic(false)
        player.set_physics_process(true)
    active = false

func final_scene() -> void:
    active = true
    if player:
        player.set_physics_process(false)
        player.camera_rig.set_cinematic(true)
    if hud:
        hud.visible = false
    await _fade_to(0.75, 0.7)
    await _text_in("УРОВЕНЬ 1", "ПРОЙДЕН")
    await get_tree().create_timer(3.0).timeout

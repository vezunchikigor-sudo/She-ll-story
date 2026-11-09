extends Control
@export var sensitivity := 1.0
var active_id := -1

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process_input(true)

func _input(event: InputEvent) -> void:
    var vp := get_viewport_rect().size
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        if touch.pressed and active_id == -1:
            # Reserve the top-right minimap and bottom action row for their own controls.
            var in_look_band := touch.position.x >= vp.x * 0.42 and touch.position.y >= vp.y * 0.30 and touch.position.y < vp.y * 0.82
            if in_look_band:
                active_id = touch.index
                get_viewport().set_input_as_handled()
        elif not touch.pressed and touch.index == active_id:
            active_id = -1
            get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag and event.index == active_id:
        var scene := get_tree().current_scene
        if scene != null:
            var player := scene.get_node_or_null("Player")
            if player != null:
                var rig := player.get_node_or_null("CameraRig")
                if rig != null:
                    rig.rotate_look(event.relative * sensitivity)
        get_viewport().set_input_as_handled()

extends Control

signal vector_changed(value: Vector2)
signal sprint_changed(active: bool)
signal block_changed(active: bool)

@export var radius := 82.0
var touch_id := -1
var value := Vector2.ZERO

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process_input(true)
    queue_redraw()

func _input(event: InputEvent) -> void:
    var rect := get_global_rect()
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        if touch.pressed and touch_id == -1 and rect.grow(22.0).has_point(touch.position):
            touch_id = touch.index
            set_joystick_global(touch.position)
            get_viewport().set_input_as_handled()
        elif not touch.pressed and touch.index == touch_id:
            touch_id = -1
            value = Vector2.ZERO
            vector_changed.emit(Vector2.ZERO)
            sprint_changed.emit(false)
            block_changed.emit(false)
            queue_redraw()
            get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag and event.index == touch_id:
        set_joystick_global(event.position)
        get_viewport().set_input_as_handled()

func set_joystick_global(pos: Vector2) -> void:
    var center := get_global_rect().get_center()
    var delta := pos - center
    delta = delta.limit_length(radius)
    value = delta / radius
    if value.length() < 0.12:
        value = Vector2.ZERO
    vector_changed.emit(value)
    sprint_changed.emit(value.y < -0.68)
    block_changed.emit(false)
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    draw_circle(center, radius, Color(0.03, 0.03, 0.03, 0.38))
    draw_arc(center, radius, 0, TAU, 64, Color(1, 1, 1, 0.36), 2.0)
    var knob := center + value * radius * 0.58
    draw_circle(knob, 31, Color(0.62, 0.62, 0.62, 0.40))
    draw_arc(knob, 31, 0, TAU, 40, Color(1, 1, 1, 0.50), 2.0)

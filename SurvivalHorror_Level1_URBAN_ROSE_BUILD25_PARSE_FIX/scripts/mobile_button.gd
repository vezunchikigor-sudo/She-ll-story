extends Button
@export var action_name:=""
@export var hold_action:=false
var pressed_visual:=false

func _ready():
    button_down.connect(_down); button_up.connect(_up)
func _down():
    pressed_visual=true
    if action_name!="": Input.action_press(action_name)
func _up():
    pressed_visual=false
    if action_name!="": Input.action_release(action_name)

extends CanvasLayer
@onready var player=get_parent().get_node("Player")
@onready var joystick=$Root/Joystick
func _ready():
    joystick.vector_changed.connect(func(v): player.set_mobile_move(v))
    joystick.sprint_changed.connect(func(v): player.set_mobile_sprint(v))
    joystick.block_changed.connect(func(v): player.set_mobile_block(v))
    $Root/AimButton.button_down.connect(func(): Input.action_press("aim"))
    $Root/AimButton.button_up.connect(func(): Input.action_release("aim"))
    $Root/FireButton.button_down.connect(func(): Input.action_press("fire"))
    $Root/FireButton.button_up.connect(func(): Input.action_release("fire"))
    $Root/ReloadButton.pressed.connect(func(): Input.action_press("reload"))
    $Root/KnifeButton.pressed.connect(func(): Input.action_press("knife"))
    $Root/CrouchButton.pressed.connect(func(): Input.action_press("crouch"))
    $Root/InteractButton.pressed.connect(func(): Input.action_press("interact"))

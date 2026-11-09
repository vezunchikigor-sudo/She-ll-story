extends Panel
@onready var joystick=$VBox/JoystickSize
@onready var alpha=$VBox/JoystickAlpha
@onready var sens=$VBox/CameraSensitivity
func _ready():
    joystick.value=GameState.joystick_size; alpha.value=GameState.joystick_alpha*100.0; sens.value=GameState.camera_sensitivity*1000.0
    joystick.value_changed.connect(func(v): GameState.joystick_size=v; GameState.save_game())
    alpha.value_changed.connect(func(v): GameState.joystick_alpha=v/100.0; GameState.save_game())
    sens.value_changed.connect(func(v): GameState.camera_sensitivity=v/1000.0; GameState.aim_sensitivity=GameState.camera_sensitivity; GameState.save_game())

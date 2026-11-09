extends CanvasLayer
@onready var hp_bar=$Root/HPBar
@onready var hp_text=$Root/HPText
@onready var ammo_text=$Root/AmmoText
@onready var med_text=$Root/MedText
@onready var weapon_text=$Root/WeaponText
@onready var critical=$Root/CriticalOverlay
@onready var player=get_parent().get_node("Player")

func _ready():
    player.combat.ammo_changed.connect(_refresh); player.combat.weapon_changed.connect(_refresh_weapon)
    get_node("/root/AudioManager").critical_health.connect(_critical)
    _refresh(player.combat.ammo,player.combat.reserve); _refresh_weapon(player.combat.weapon); _update_hp()

func _process(_delta): _update_hp()
func _update_hp():
    var hp=player.hp; hp_bar.value=hp; hp_text.text="HP %d"%hp; med_text.text="М %d  Б %d"%[GameState.small_medkits,GameState.large_medkits]
func _refresh(current,reserve): ammo_text.text="%03d / %03d"%[current,reserve]
func _refresh_weapon(name): weapon_text.text=name
func _critical(active): critical.visible=active

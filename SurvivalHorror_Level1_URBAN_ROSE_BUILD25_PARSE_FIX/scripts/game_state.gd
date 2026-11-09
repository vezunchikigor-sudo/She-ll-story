extends Node

var hp := 100
var small_medkits := 4
var large_medkits := 1
var survivor_medicine := 1
var current_level := 1
var flags: Dictionary = {}
var camera_sensitivity := 0.010
var aim_sensitivity := 0.006
var joystick_size := 1.0
var joystick_alpha := 1.0
var graphics_quality := "High"
var language := "Russian"
var weapon_reserve = {"Pistol":120, "Shotgun":18, "Uzi":150, "RocketLauncher":1}
const SAVE_PATH := "user://urban_rose_save.json"

func save_game() -> void:
    var data := {
        "hp": hp, "small_medkits": small_medkits, "large_medkits": large_medkits,
        "survivor_medicine": survivor_medicine, "current_level": current_level,
        "flags": flags, "camera_sensitivity": camera_sensitivity,
        "aim_sensitivity": aim_sensitivity, "joystick_size": joystick_size,
        "joystick_alpha": joystick_alpha, "graphics_quality": graphics_quality,
        "language": language, "weapon_reserve": weapon_reserve
    }
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(data))
        f.close()

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if f == null:
        return false
    var parsed: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        return false
    hp = int(parsed.get("hp", hp))
    small_medkits = int(parsed.get("small_medkits", small_medkits))
    large_medkits = int(parsed.get("large_medkits", large_medkits))
    survivor_medicine = int(parsed.get("survivor_medicine", survivor_medicine))
    current_level = int(parsed.get("current_level", current_level))
    flags = parsed.get("flags", {})
    camera_sensitivity = float(parsed.get("camera_sensitivity", camera_sensitivity))
    aim_sensitivity = float(parsed.get("aim_sensitivity", aim_sensitivity))
    joystick_size = float(parsed.get("joystick_size", joystick_size))
    joystick_alpha = float(parsed.get("joystick_alpha", joystick_alpha))
    graphics_quality = str(parsed.get("graphics_quality", graphics_quality))
    language = str(parsed.get("language", language))
    weapon_reserve = parsed.get("weapon_reserve", weapon_reserve)
    return true

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

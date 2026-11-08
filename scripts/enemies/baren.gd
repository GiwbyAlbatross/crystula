class_name Baren
extends Enemy

@export var WALK_SPEED = 200.0

func _initialise() -> void:
	flags[&'flip'] = false

func _be_intelligent(delta: float) -> void:
	pass

func _on_dmg() -> void:
	pass

func is_invulnerable() -> bool:
	return !(flags[&'flip'])

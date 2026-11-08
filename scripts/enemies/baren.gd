class_name Baren
extends Enemy

@export var WALK_SPEED = 300.0

func _initialise() -> void:
	flags[&'flip'] = false
	cooldowns[&'flip_back'] = 0.0

func _be_intelligent(delta: float) -> void:
	if flags[&'flip']:
		velocity.x *= delta*2.2
	else:
		velocity.x = _get_player_x() * WALK_SPEED
		anim.flip_h = _get_player_x() > 0.0
	if cooldowns[&'flip_back'] < 0.0 and flags[&'flip']:
		flags[&'flip'] = false
		anim.play(&'flipping')
		print("flipping back")

func _pick_next_anim() -> void:
	if flags[&'flip']:
		anim.play(&'flipped')
	else:
		anim.play(&'default')

func _on_pogo() -> void:
	if flags[&'flip']:
		cooldowns[&'flip_back'] += 1.0
		return
	cooldowns[&'flip_back'] = 6.0 # you have 6 seconds until it flips back and becomes immortal again
	flags[&'flip'] = true
	anim.play(&'flipping')

func is_invulnerable() -> bool:
	return !(flags[&'flip'])

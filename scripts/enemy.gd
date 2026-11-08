class_name Enemy
extends CharacterBody2D
# provides the very lowest imple behaviour for incredibly simple enemies. Inherit this class and override _be_intelligent to implement good enemy behaviour

@export var intelligence_frequency := 50 # how many ticks between running _be_intelligent
@export var bounciness := 0.1 #         # how much recoil the plyer should take upon hitting
@export var random_intel_ticks := 0.0 # # chance that any given tick will run _be_intelligent
@export var sprite_flash := true

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var flags: Dictionary[StringName, bool] = {}
var cooldowns: Dictionary[StringName, float] = {
	&'dmg':0.0
}

var hp := 1.0 # set this in subclass _initialise
var alive_ticks: int
var alive_time: float
var last_intel_time: float = -1

signal dmg(amt: float)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	alive_ticks = 0
	alive_time = 0.0
	dmg.connect(_dmg)
	anim.animation_looped.connect(_pick_next_anim)
	anim.animation_finished.connect(_pick_next_anim)
	_initialise() # should be overriden by a child class

func _dmg(amt: float) -> void:
	# enemy behaviour: no dmg cooldowm
	print_debug(name, " taking ", amt, " damage")
	
	if is_invulnerable():
		return
	hp -= amt
	if sprite_flash:
		modulate = Color(100.1, 100.1, 100.1)
	_on_dmg()
	return
	
	# player behaviour
	@warning_ignore("unreachable_code")
	if _check_cooldown(&'dmg'):
		hp -= amt
		_set_cooldown(&'dmg', sqrt(amt/2.0))
	

func _set_cooldown(_name: StringName, length: float) -> bool:
	"""set a cooldown and return whether or not it had expired""" # good ol python docsrtring
	var expired = _check_cooldown(name)
	cooldowns[name] = length
	return expired

func _check_cooldown(_name: StringName) -> bool:
	"""check whether or not a given cooldown has cooled down"""
	return cooldowns[name] < 0.0

func _get_player_diff() -> Vector2:
	"""get a vector pointing toward the player from this enemy's origin point
	returned value will not necessarily be normalised"""
	return PlayerStats.position - global_position
func _get_player_distance() -> float:
	"""get the distance to the player
	equivalent to _get_player_diff().length()"""
	return (PlayerStats.position - global_position).length()
func _get_player_direction() -> Vector2:
	"""get the direction to the player
	returned direction should be normalised"""
	return (PlayerStats.position - global_position).normalized()
func _get_player_x() -> float:
	"""get the direction to walk horizontally to be closest to the player
	should almost always be -1.0 or 1.0"""
	return clampf((PlayerStats.position - global_position).x * 100000.1, -1.0, 1.0)

@warning_ignore("unused_parameter") # THIS MEANS IT'S AN ABSTRACT METHOD
func _initialise() -> void:
	"""OVERRIDE THIS TO SET VALUES ON ENTERING SCENE TREE"""

@warning_ignore("unused_parameter")
func _on_dmg() -> void:
	"""OVERRIDE THIS TO MAKE SOMETHING HAPPEN WHEN TAKING DAMAGE"""

@warning_ignore("unused_parameter")
func _pick_next_anim() -> void:
	pass

@warning_ignore("unused_parameter")
func _vfx(delta: float) -> void:
	"""OVERRIDE THIS NOT _process
	runs every frame"""

@warning_ignore("unused_parameter")
func is_invulnerable() -> bool:
	"""OVERRIDE THIS TO MAKE ENEMIES INVULNERABLE SOMETIMES"""
	return false

@warning_ignore("unused_parameter")
func _be_intelligent(delta: float) -> void:
	"""OVERRIDE THIS
	runs every `intelligence_frequency` physics ticks (at 60tps)"""
	
	# base behaviour for dumb ememies
	if motion_mode == MotionMode.MOTION_MODE_FLOATING:
		velocity = _get_player_direction() * 300.0
	else:
		velocity.x = _get_player_x() * 350.0
	#print("being intelligent")

@warning_ignore("unused_parameter")
func _physics(delta: float) -> void:
	"""OVERRIDE THIS TO HAVE PHYSICS RUN EVERY TICK (60tps)"""
	if !is_on_floor() and motion_mode == MotionMode.MOTION_MODE_GROUNDED:
		velocity.y += 10000.0 * delta

@warning_ignore("unused_parameter")
func _react(delta: float) -> void:
	"""OVERRIDE THIS
	is called every physics tick (at 60tps)
	use this to quickly react to events and avoid doing expensive calculations here"""

@warning_ignore("unused_parameter")
func _on_pogo() -> void:
	"""OVERRIDE THIS TO MAKE THINGS HAPPEN WHEN POGO'D"""

func _physics_process(delta: float) -> void:
	alive_ticks += 1
	if ((alive_ticks % intelligence_frequency) == 0) or (randf() < random_intel_ticks):
		_be_intelligent(alive_time - last_intel_time)
		last_intel_time = alive_time
	_react(delta)
	_physics(delta)
	
	move_and_slide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_vfx(delta)
	if sprite_flash:
		modulate = lerp(modulate, self_modulate, delta*30.3)
	alive_time += delta
	
	# see res://scripts/player.gd:_tick_cooldowns
	for key in cooldowns:
		cooldowns[key] -= delta

class_name Enemy
extends CharacterBody2D
# provides the very lowest imple behaviour for incredibly simple enemies. Inherit this class and override _be_intelligent to implement good enemy behaviour

@export_custom(PROPERTY_HINT_NONE, "How many frames between calling _be_intelligent. Basically reaction time of the enemy.") var intelligence_frequency := 5

var flags: Dictionary[StringName, bool] = {}
var cooldowns: Dictionary[StringName, float] = {}

var hp := 1.0 # set this in subclass _initialise
var alive_ticks: int
var alive_time: float
var last_intel_time: float = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	alive_ticks = 0
	alive_time = 0.0
	_initialise() # should be overriden by a child class

func _set_cooldown(_name: StringName, length: float) -> bool:
	"""set a cooldown and return whether or not it had expired"""
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

@warning_ignore("unused_parameter")
func _initialise() -> void:
	"""OVERRIDE THIS TO SET VALUES ON ENTERING SCENE TREE""" # good ol python docsrtring

@warning_ignore("unused_parameter")
func _vfx(delta: float) -> void:
	"""OVERRIDE THIS NOT _process
	runs every frame"""

@warning_ignore("unused_parameter")
func _be_intelligent(delta: float) -> void:
	"""OVERRIDE THIS
	runs every `intelligence_frequency` physics ticks (at 60tps)"""

@warning_ignore("unused_parameter")
func _react(delta: float) -> void:
	"""OVERRIDE THIS
	is called every physics tick (at 60tps)
	use this to quickly react to events and avoid doing expensive calculations here"""

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	alive_ticks += 1
	if (alive_ticks % intelligence_frequency) == 0:
		_be_intelligent(alive_time - last_intel_time)
		last_intel_time = alive_time
	_react(delta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_vfx(delta)
	alive_time += delta

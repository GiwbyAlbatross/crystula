class_name Yathero
extends CharacterBody2D

# settings
@export var SPEED := 500.0
@export var JUMP_VELOCITY := -1000.0
@export var JUMP_BOOST := 4500.0
@export var JUMP_LENGTH := 1.0 # seconds
@export var GRAVITY := 6000.0
@export var maxhp: float = 5.0
@export var preserved_animations := PackedStringArray(['attack_0', 'uppercut', 'pogo'])
@export var coyote_time := 0.1

# onreadies
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var flipper: Node2D = $flipper # just flips other nodes using scale.x

var hp: float = 5.0
var flags: Dictionary[StringName, bool] = {
	&'pogoing':false
} # to avoid having a million goddamn booleans
var cooldowns: Dictionary[StringName, float] = { # see _tick_cooldowns
	&'no_input':0.0, # bloody *&^%ing no-input time that pmo in hk so much but is kinda important (DON'T OVERDO IT)
	&'jump':0.0,
	&'coyote':0.0,
	&'dash':0.0, # dashing if greater than 0.0, can dash if less than -0.45 TODO: implement dashing
	&'dmg':0.0,
	&'attack': 0.0, # attacking if greater than 0.0, can attack if less than -0.1
} # to avoid having a million goddamn floats for evey cooldown
var peakheight := 10.0**100.0

# important movement stuff
var direction := 0.0
var facing := -1 # negative is left, positive is right, should never be zero
var knockback := Vector2.ZERO

# important combat stuff
var attack_hitbox: Area2D
var already_attacked: Array[CollisionObject2D] = []

signal dmg(amt: float) # when hit, call this

func _ready() -> void:
	anim.animation_looped.connect(_pick_next_anim)
	anim.animation_finished.connect(_pick_next_anim)
	PlayerStats.object = self

func _on_dmg(amt: float) -> void:
	if cooldowns[&'dmg']:
		hp -= amt / 5.0
		cooldowns[&'dmg'] = sqrt(amt/2.0)

func _pick_next_anim():
	var last: StringName = anim.animation
	if !direction:
		if is_on_floor():
			anim.play(&'idle')
		else:
			anim.play(&'fall')
	else:
		# TODO: check for running
		anim.play(&'walk')
	#print("setting next animation, last: '", last, "', new: '", anim.animation, "'")

func setanim(a: StringName) -> void:
	# preserves certain important animations
	if !(preserved_animations.has(anim.animation)) and anim.is_playing():
		anim.play(a)

func _move(delta: float) -> void:
	# DO MOVEMENT
	
	# Add the gravity.
	if not is_on_floor():
		peakheight = min(peakheight, global_position.y)
		velocity.y += GRAVITY * delta
		if velocity.y < 100.0:
			setanim(&'fall')
	
	if is_on_floor():
		cooldowns[&'coyote'] = coyote_time + delta
	
	if cooldowns[&'no_input'] > 0.0:
		# we are in no-input time
		return

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		facing = direction
		setanim(&'walk')
		velocity.x = direction * SPEED
	else:
		if Input.is_action_just_released("move") and is_on_floor():
			setanim(&'idle')
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Handle jump after movement so the animations don't overwrite each other
	
	if Input.is_action_pressed("ui_accept") and cooldowns[&'jump'] > 0.0 and !is_on_floor() and velocity.y <= 0.0:
		velocity.y -= JUMP_BOOST * delta
	if Input.is_action_just_released("ui_accept") and cooldowns[&'jump'] >= 0.0:
		velocity.y *= 0.1
	
	if cooldowns[&'coyote'] >= 0.0:
		if Input.is_action_just_pressed("ui_accept"):
			cooldowns[&'jump'] = JUMP_LENGTH
			cooldowns[&'coyote'] = 0.0
			velocity.y = JUMP_VELOCITY
			anim.play(&"jump_raw")
		elif anim.animation == &'jump_raw':
			anim.play(&"idle")
		elif peakheight < global_position.y-150.51:
			setanim(&'fall-land')

func _combat(_delta: float) -> void:
	# WIP: actual combat logic
	if Input.is_action_just_pressed('attack') and cooldowns[&'attack'] < -0.1:
		cooldowns[&'attack'] = 0.35
		already_attacked.clear()
		flags[&'pogoing'] = false
		if Input.is_action_pressed('ui_up'):
			# uppercut attack
			anim.play(&'uppercut')
			#
			attack_hitbox = flipper.get_node("uppercut")
		elif Input.is_action_pressed('ui_down') and !is_on_floor():
			anim.play(&'pogo')
			attack_hitbox = flipper.get_node("pogo")
			flags[&'pogoing'] = true
		else:
			attack_hitbox = flipper.get_node("swipeattack")
			anim.play(&"attack_0")
		attack_hitbox.get_node("Sprite2D").play() # will crash when doing dash attack FIXME later
	if cooldowns[&'attack'] > 0.0:
		for body in attack_hitbox.get_overlapping_bodies():
			if 'dmg' in body and body != self:
				# can be hit
				if !already_attacked.has(body):
					body.dmg.emit(PlayerStats.atk_dmg)
					already_attacked.append(body)
					if flags[&'pogoing']:
						body._on_pogo()
				else:
					body.dmg.emit(0.1) # extra damage for more time in attack hitbox; cool mechanic that makes timing more important kind anot really idk :sigh: </yap>

# WELP actually we don't need this to be a function bc we only need it once and functions are expensive
func _tick_cooldowns(delta: float) -> void:
	# very simple timer logic that doesn't use the timer node
	# to set a timer, set cooldowns[&'your_cooldown_name'] to however long that cooldown is
	# and when it's over it will be <= 0.0
	for key in cooldowns:
		cooldowns[key] -= delta

func _physics_process(delta: float) -> void: # runs exactly 60 times a second, regardless of fps
	_move(delta)
	_combat(delta)
	
	flipper.scale.x = -facing
	
	if is_on_floor():
		peakheight = global_position.y
	
	PlayerStats.hp = hp
	PlayerStats.position = global_position
	
	#_tick_cooldowns(delta)
	for key in cooldowns:
		cooldowns[key] -= delta
	
	move_and_slide()

func _process(delta: float) -> void: # runs every frame, affected by FPS
	# TODO: VFX and stuff here
	anim.flip_h = facing > 0

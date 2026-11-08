extends Sprite2D

@export var onload_frame := 7 # very specific to one use case 
@export var end_frame := -1
@export var frame_rate := 30.0

var playing := false
var frame_upto := 0.0
var end: int

func _ready() -> void:
	frame = onload_frame

func play(start := 0.0) -> void:
	"""call to play the animation
	`start` is the frame to start on
		if fractional, the fractional component will be subtracted off how long the first frame is visible for, just as a byproduct of the implementation
		normally, `start` should be a whole number"""
	playing = true
	end = end_frame
	if end == -1:
		end = vframes * hframes
	frame_upto = start
	frame = float(start)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var period = 1. / frame_rate
	if playing:
		if frame != end:
			frame_upto += delta/period
		else:
			playing = false
		frame = int(frame_upto)
			

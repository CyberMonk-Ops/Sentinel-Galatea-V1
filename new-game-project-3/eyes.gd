extends Control

# REFERENCES
# Make sure your IRIS is a Child of SCLERA for this to work!
@onready var left_eye_root = $EyesContainer/Eye_Left
@onready var left_iris = $EyesContainer/Eye_Left/Sclera/Iris
@onready var left_lid_top = $EyesContainer/Eye_Left/Upper_Eyelid
@onready var left_lid_bottom = $EyesContainer/Eye_Left/Lower_Eyelid

@onready var right_eye_root = $EyesContainer/Eye_Right
@onready var right_iris = $EyesContainer/Eye_Right/Sclera/Iris
@onready var right_lid_top = $EyesContainer/Eye_Right/Upper_Eyelid
@onready var right_lid_bottom = $EyesContainer/Eye_Right/Lower_Eyelid

signal change_waifu_mood(mood_name)
var time_since_last_packet: float = 0.0 # Watchdog timer
var continuous_face_time: float = 0.0   # How long we have stared
var is_face_lost: bool = true           # Current state
# SETTINGS
var max_move_radius = 405.0 # Since your scale is 0.05, ~25px is a good move range
var blink_timer = 0.0
var next_blink = 3.0
var current_look_dir = Vector2(0, 0)
var use_network = true 


func _ready() -> void:
	var listener = $NetworkListener 
	listener.on_look_command.connect(update_look_from_network)
	listener.on_blink_command.connect(blink)
	

func update_look_from_network(x, y):
	var look_dir = Vector2(x, y)
	use_network = true 
	current_look_dir = Vector2(x, y)
	print("NET: ", current_look_dir) # Un
	
	time_since_last_packet = 0.0 
		
			# If we were previously lost, tell the system we found the face
	if is_face_lost:
		is_face_lost = false
		emit_signal("change_waifu_mood", "NEUTRAL")
		get_tree().call_group("waifu_face", "set_mood_from_string", "NEUTRAL")



func _process(delta):
	# 1. TRACK THE MOUSE (Simulated Face Tracking)
	var screen_center = get_viewport_rect().size / 2
	if use_network == false:
		var mouse_pos = get_global_mouse_position()
		var look_dir = (mouse_pos - screen_center) / (screen_center.x)
		look_dir = look_dir.clamp(Vector2(-1, -1), Vector2(1, 1))
		update_eye(left_iris, look_dir, delta)
		update_eye(right_iris, look_dir, delta)
	elif use_network == true:
		update_eye(left_iris, current_look_dir, delta)
		update_eye(right_iris, current_look_dir, delta)
	# Get a value from -1 (Left) to +1 (Right)
	
	# 2. MOVE EYES
	time_since_last_packet += delta
		
		# CHECK 1: DID WE LOSE THE FACE? (No packet for 1.0 second)
	if time_since_last_packet > 1.0:
		
		is_face_lost = true
		continuous_face_time = 0.0 # Reset happy timer
		emit_signal("change_waifu_mood", "ANGRY") # Triggers Frown
		print("Face Lost! Getting Angry...")
		get_tree().call_group("waifu_face", "set_mood_from_string", "ANGRY")
		
		# CHECK 2: ARE WE STARING? (Face is here)
	else:
		is_face_lost = false
		continuous_face_time += delta
			
			# If looked at for > 5 seconds, get HAPPY
		if continuous_face_time > 5.0:
			# We limit this so it doesn't spam the signal every frame
			# (You can add a check in your WaifuFace script to ignore duplicates)
			emit_signal("change_waifu_mood", "HAPPY") 
			get_tree().call_group("waifu_face", "set_mood_from_string", "HAPPY")
	
	
	
	
	# 3. BLINK LOGIC
	blink_timer += delta
	if blink_timer > next_blink:
		blink()
		blink_timer = 0
		next_blink = randf_range(2.0, 5.0) # Random blinking

func update_eye(iris: TextureRect, direction: Vector2, delta: float):
	# Since Iris is a child of Sclera, (0,0) is the top-left of the Sclera.
	# We need to find the CENTER of the Sclera.
	
	var sclera_size = iris.get_parent().get_size() # Get size of the mask
	var iris_size = iris.get_size() * iris.scale   # Get real size of Iris
	
	# Center Point = Half the Sclera Size - Half the Iris Size
	var center_pos = (sclera_size / 2) - (iris_size / 2)
	
	# Target = Center + (Direction * Radius)
	var target = center_pos + (direction * max_move_radius)
	
	# Smooth Move
	iris.position = iris.position.lerp(target, 10 * delta)

func blink():
	# Animate the Eyelids closing
	var tween = create_tween()
	
	# 1. Close (Move Y position)
	# Adjust these values based on where your lids are placed!
	# Assuming lids are normally at Y=0 (Open) and need to go to Y=50 (Closed)
	var close_pos_top = 40 
	var close_pos_bot = -4
	var open_pos_top = 0
	var open_pos_bot = 0
	
	# Speed: 0.1s
	tween.parallel().tween_property(left_lid_top, "position:y", close_pos_top, 0.1)
	tween.parallel().tween_property(left_lid_bottom, "position:y", close_pos_bot, 0.1)
	tween.parallel().tween_property(right_lid_top, "position:y", close_pos_top, 0.1)
	tween.parallel().tween_property(right_lid_bottom, "position:y", close_pos_bot, 0.1)
	
	# 2. Wait
	tween.tween_interval(0.05)
	
	# 3. Open
	tween.parallel().tween_property(left_lid_top, "position:y", open_pos_top, 0.1)
	tween.parallel().tween_property(left_lid_bottom, "position:y", open_pos_bot, 0.1)
	tween.parallel().tween_property(right_lid_top, "position:y", open_pos_top, 0.1)
	tween.parallel().tween_property(right_lid_bottom, "position:y", open_pos_bot, 0.1)

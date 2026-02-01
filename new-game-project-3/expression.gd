extends Node2D

@onready var lip_line = $lip

# --- CONFIG ---
@export var spring_stiffness: float = 150.0
@export var spring_damping: float = 10.0
@export var lip_width: float = 60.0 # How wide the mouth is

# --- STATE ---
var target_y: float = 0.0 # Where the center wants to be (0 = Neutral, 10 = Smile, -10 = Frown)
var current_y: float = 0.0 # Where the center actually is
var velocity_y: float = 0.0 # Physics velocity

# --- MOUSE INTERACTION ---
var is_dragged: bool = false

@onready var brow_l = $eyebrows/Control/eyebrow_l
@onready var brow_r = $eyebrows/Control2/eyebrow_r

# --- SETTINGS ---
@export var brow_neutral_rot: float = 0.0
@export var brow_angry_rot: float = 15.0 # Degrees
@export var brow_sad_rot: float = -10.0
@export var brow_height_normal: float = 0.0 # Adjust based on your layout
@export var brow_height_raised: float = -65.0

var current_tween: Tween

# --- EXPRESSION STATES ---
var mood=["NEUTRAL","HAPPY","SHY","ANGRY"]
enum Mood { NEUTRAL, HAPPY, SHY, ANGRY }
var current_mood = Mood.NEUTRAL






func _ready():
	add_to_group("waifu_face") 
	# Connect your cheek signals here if you haven't via editor
	# $HeadPivot/CheeksGroup/CheekLeft.connect("poked", _on_cheek_poked)
	#reset_face()
	lip_line.clear_points()
	lip_line.add_point(Vector2(-lip_width, -5)) # Left
	lip_line.add_point(Vector2(-lip_width+3, -3)) # Left
	lip_line.add_point(Vector2(0, 0))    
	lip_line.add_point(Vector2(lip_width-3, -3)) # Left# Center
	lip_line.add_point(Vector2(lip_width, -5))  # Right
	var cheek_left_node = get_node_or_null("../cheekanchor_left/cheek_left")
	if cheek_left_node:
		cheek_left_node.poked_me.connect(_on_cheek_poked)
	else:
		print("ERROR: Could not find Left Cheek! Check path.")
	# Try to find the Right Cheek
	var cheek_right_node = get_node_or_null("../cheekanchor_right/cheek_right")
	if cheek_right_node:
		cheek_right_node.poked_me.connect(_on_cheek_poked)
	#var eye =get_parent()
	#eye.check_waifu_mood.connect(change_mood)


func set_mood_from_string(mood_name: String):
	print("d")
	match mood_name:
		"HAPPY":
			set_mood(Mood.HAPPY)
		"ANGRY":
			if current_mood!=Mood.SHY:
				set_mood(Mood.ANGRY)
		"SHY":
			set_mood(Mood.SHY)
		"NEUTRAL":
			set_mood(Mood.NEUTRAL)
			


func _on_cheek_poked():
	print("Ouch! I am Shy now.")
	set_mood(Mood.SHY)
	
	# Reset to Neutral after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if current_mood == Mood.SHY: # Only reset if we are still shy
		set_mood(Mood.NEUTRAL)



func _process(delta):
	# 1. SPRING PHYSICS
	# Force = (Target - Current) * Stiffness - (Velocity * Damping)
	var displacement = target_y - current_y
	var force = displacement * spring_stiffness
	var damping_force = velocity_y * spring_damping
	
	var acceleration = force - damping_force
	
	# Only apply physics if NOT being dragged by mouse (for the "Smoothered" feel)
	if not is_dragged:
		velocity_y += acceleration * delta
		current_y += velocity_y * delta
	
	# 2. UPDATE GRAPHICS
	# We only move point index 1 (The Center Point)
	lip_line.set_point_position(2, Vector2(0, current_y))
	

	
func _on_mouth_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.pressed:
			is_dragged = true
		else:
			is_dragged = false
			# THE RELEASE SNAP
			# When you let go, add chaotic velocity for that "Jiggle"
			velocity_y += randf_range(-100, 100) 
	
	if event is InputEventMouseMotion and is_dragged:
		# Direct control - "Smoothered" feel
		# The lip follows your mouse Y position, clamped so you don't break her face
		current_y = clamp(get_local_mouse_position().y, -20, 30)


	if event is InputEventMouseMotion and is_dragged:
		# Direct control - "Smoothered" feel
		# The lip follows your mouse Y position, clamped so you don't break her face
		current_y = clamp(get_local_mouse_position().y, -10, 10)
		
	
func set_mood(mood:Mood):
	current_mood = mood# mood[a]
	#if current_mood==mood[2]
		#current_mood=Mood.SHY
		#print("1")
	# Kill old animation to prevent fighting
	if current_tween: current_tween.kill()
	current_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	match mood:
		Mood.NEUTRAL:
			_animate_brows(brow_neutral_rot, brow_height_normal)
			_set_mouth("neutral")
			
		Mood.HAPPY: # Triggered by Face Track > 5s
			_animate_brows(-5.0, brow_height_raised) # Slightly raised "Ah!" look
			_set_mouth("smile")
			
		Mood.SHY: # Triggered by Poke
			_animate_brows(brow_sad_rot, brow_height_normal-15) # "W-what are you doing?" look
			_set_mouth("open")
			
		Mood.ANGRY:
			_animate_brows(brow_angry_rot, brow_height_normal - 20) # Furrowed and low
			_set_mouth("frown")
			
			
func _animate_brows(rot_angle: float, height: float):
	# Left Brow (Rotate normal)
	current_tween.tween_property(brow_l, "rotation_degrees", rot_angle, 0.5)
	current_tween.tween_property(brow_l, "position:y", height, 0.5)
	
	# Right Brow (Mirror rotation)
	current_tween.tween_property(brow_r, "rotation_degrees", -rot_angle, 0.5)
	current_tween.tween_property(brow_r, "position:y", height, 0.5)

			

func _set_mouth(mood_string: String):
	match mood_string:
		"smile":
			target_y = 15.0 # Curve Down (Godot Y is down) -> Smile
		"frown":
			target_y = -10.0 # Curve Up -> Sad/Angry
		"neutral":
			target_y = 0.0 # Flat
		"open":
			# For "Open" mouth (O shape), we cheat:
			# Just drop the jaw way down. It looks like a gasp.
			target_y = 25.0 
	
	
	


func _on_mouth_area_mouse_exited() -> void:
	
	is_dragged = false
			# THE RELEASE SNAP
			# When you let go, add chaotic velocity for that "Jiggle"
	velocity_y += randf_range(-10, 10)
	 # Replace with function body.

extends TextureRect # Changed from Sprite2D to TextureRect for UI input

# --- PHYSICS CONSTANTS ---
@export var spring_stiffness: float = 200.0
@export var damp_factor: float = 15.0
@export var mass: float = 1.0
@export var sensitivity: float = 2.0 # Multiplier for touch force


@export var blush_color: Color = Color(1, 0.4, 0.4, 0) # Start invisible (Alpha 0)
@export var angry_color: Color = Color(1, 0.2, 0.2, 0.8) # Red when poked hard
var current_tween: Tween
# --- STATE ---
var velocity: Vector2 = Vector2.ZERO
var displacement: Vector2 = Vector2.ZERO
var default_pos: Vector2
var is_shy=false
signal poked_me

func _ready():
	default_pos = position # Remember where the cheek sits normally
	modulate = blush_color 

func _gui_input(event):
	# DETECT SWIPE / DRAG
	if event is InputEventScreenDrag or (event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		
		# 'event.relative' is the speed/direction of the finger
		var swipe_force = event.relative * sensitivity
		
		# Apply the force to the velocity (Kick the system)
		#velocity += swipe_force / mass
		poked_me.emit() 
		# Optional: Add "Randomness" here if you want stochastic behavior
		velocity += swipe_force * randf_range(0.9, 1.1)/mass
		trigger_blush()
		is_shy=true
func _process(delta):
	#shy()
	# --- SPRING PHYSICS (Same as before) ---
	var spring_force = -spring_stiffness * displacement
	var damping_force = -damp_factor * velocity
	var acceleration = (spring_force + damping_force) / mass
	
	velocity += acceleration * delta
	displacement += velocity * delta
	
	# Update Position (Relative to the Anchor)
	position = default_pos + displacement
	
	# SQUASH & STRETCH (Visual Polish)
	# Stretch along the movement axis
	if velocity.length() > 10:
		var deform = 1.0 + (velocity.length() * 0.0005)
		# Clamp deform to avoid exploding sprites
		deform = clamp(deform, 1.0, 1.2)
		scale = Vector2(deform, 1.0/deform)
		#rotation = velocity.angle() # Rotate to face movement
	else:
		# Return to normal
		scale = scale.lerp(Vector2(1,1), delta * 10)
		#rotation = lerp_angle(rotation, 0, delta * 10)

func trigger_blush():
	# Kill old tween if running so we don't conflict
	if current_tween:
		current_tween.kill()
	current_tween = create_tween()
# Flash to ANGRY/SHY color instantly
	current_tween.tween_property(self, "modulate", angry_color, 0.1)
# Slowly fade back to invisible over 2 seconds
	current_tween.tween_property(self, "modulate", blush_color, 2.0).set_delay(0.2)
	
	

func shy():
	if is_shy == true:
		pass#get_node("expression").set_mood(2)
		

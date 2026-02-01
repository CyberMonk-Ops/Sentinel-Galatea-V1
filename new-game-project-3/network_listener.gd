extends Node

# THE PORT (Must match Python)
var udp := PacketPeerUDP.new()
var PORT = 4242

# SIGNAL (To tell the eyes where to look)
signal on_look_command(x, y)
signal on_blink_command()

func _ready():
	# Start listening on Localhost:4242
	if udp.bind(PORT) == OK:
		print(">>> GODOT LISTENING ON PORT " + str(PORT))
	else:
		print(">>> FAILED TO BIND PORT!")

func _process(delta):
	# Check if packets are waiting
	while udp.get_available_packet_count() > 0:
		var packet = udp.get_packet()
		var message = packet.get_string_from_utf8()
		
		# Message Format: "LOOK:0.5,-0.2" or "BLINK"
		parse_message(message)

func parse_message(msg: String):
	# Clean whitespace
	msg = msg.strip_edges()
	
	if msg.begins_with("LOOK:"):
		# Extract numbers
		var data = msg.trim_prefix("LOOK:")
		var parts = data.split(",")
		if parts.size() == 2:
			var x = float(parts[0])
			var y = float(parts[1])
			emit_signal("on_look_command", x, y)
			
	elif msg == "BLINK":
		emit_signal("on_blink_command")

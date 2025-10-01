# DialogueSystem.gd
extends CanvasLayer

signal dialogue_finished

# Get references to the nodes in the scene tree
@onready var dialogue_box = $DialogueBox 
@onready var name_label = $DialogueBox/NameLabel 
@onready var text_label = $DialogueBox/TextLabel
@onready var continue_indicator = $DialogueBox/ContinueIndicator 
@onready var typewriter_timer = $TypewriterTimer # YOU MUST ADD A TIMER NODE NAMED 'TypewriterTimer'

# Variables to manage the state of the dialogue
var dialogue_data: Array = []
var current_index: int = 0
var is_active: bool = false

# --- NEW STATE VARIABLES FOR TYPEWRITER EFFECT ---
var full_text: String = "" # Holds the entire text for the current line
var char_index: int = 0 # Tracks how many characters have been displayed
var is_typing: bool = false # Flag to indicate if the typewriter effect is running
const TYPING_SPEED: float = 0.05 # Delay in seconds between characters

func _ready():
	# Called when the node enters the scene tree for the first time.
	hide_dialogue() # Start the game with the dialogue box hidden.
	# --- NEW: Connect the Timer's timeout signal ---
	typewriter_timer.timeout.connect(_on_typewriter_timer_timeout)

func start_dialogue(dialogue_array: Array):
	# Public function to begin a new dialogue sequence.
	dialogue_data = dialogue_array
	current_index = 0
	is_active = true
	show_current_dialogue()

func show_current_dialogue():
	# Internal function to display the dialogue line at current_index.
	
	if current_index >= dialogue_data.size():
		end_dialogue()
		return
	
	var current = dialogue_data[current_index]
	dialogue_box.show()
	
	# Set speaker name (optional)
	if current.has("speaker"):
		name_label.text = current.speaker
		name_label.show()
	else:
		name_label.hide()
	
	# --- TYPEWRITER SETUP ---
	full_text = current.text # Store the full text
	char_index = 0 # Reset character counter
	text_label.text = "" # Clear the text label before typing
	continue_indicator.hide() # Hide indicator while typing
	is_typing = true # Set the flag
	typewriter_timer.wait_time = TYPING_SPEED
	typewriter_timer.start() # Start the typing effect
	
	# Handle camera pan if specified
	if current.has("camera_target"):
		# pan_duration defaults to 1.0 if not specified
		pan_camera_to(current.camera_target, current.get("pan_duration", 1.0))

# --- NEW FUNCTION: Timer Callback ---
func _on_typewriter_timer_timeout():
	if char_index < full_text.length():
		# Append the next character to the text_label
		text_label.text += full_text[char_index]
		char_index += 1
	else:
		# Typing is finished
		typewriter_timer.stop()
		is_typing = false
		continue_indicator.show() # Show indicator, ready for player to advance

# --- NEW FUNCTION: Skip Typing ---
func skip_typewriter():
	typewriter_timer.stop() # Stop the timer
	text_label.text = full_text # Instantly show the entire text
	is_typing = false # Reset the flag
	continue_indicator.show() # Show indicator

func hide_dialogue():
	# Hides all parts of the dialogue interface.
	dialogue_box.hide()
	continue_indicator.hide()

func next_dialogue():
	# Advances to the next line of dialogue.
	if not is_active:
		return # Do nothing if the dialogue system isn't currently active.
		
	current_index += 1 # Increment the index to move to the next line.
	show_current_dialogue() # Display the new current dialogue line.

func end_dialogue():
	# Function called when the entire dialogue array has been displayed.
	is_active = false # Deactivate the system.
	hide_dialogue() # Hide the interface.
	dialogue_finished.emit() # Emit the signal so other nodes can react (e.g., unpause the game).

func pan_camera_to(target_position: Vector2, duration: float):
	# Moves the game's main 2D camera to a new position smoothly.
	var camera = get_viewport().get_camera_2d() # Get the active Camera2D node in the viewport.
	if camera:
		var tween = create_tween() # Create a Tween object for smooth animation.
		# Animate the camera's global_position from its current spot to the target_position over the specified duration.
		tween.tween_property(camera, "global_position", target_position, duration)

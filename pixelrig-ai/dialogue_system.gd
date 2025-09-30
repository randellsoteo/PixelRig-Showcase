# DialogueSystem.gd
extends CanvasLayer # Inherits from CanvasLayer, meaning it's a UI element that draws above the 2D world.

signal dialogue_finished # Define a custom signal that will be emitted when the entire dialogue sequence is done.

# Get references to the nodes in the scene tree when the script starts (pag start, naga run dayon - this note confirms your understanding of @onready)
@onready var dialogue_box = $DialogueBox 
@onready var name_label = $DialogueBox/NameLabel 
@onready var text_label = $DialogueBox/TextLabel
@onready var continue_indicator = $DialogueBox/ContinueIndicator # An element (like an arrow or icon) that indicates the player can continue.

# Variables to manage the state of the dialogue
var dialogue_data: Array = [] # Array to hold all the dialogue lines/blocks (e.g., speaker, text, actions).
var current_index: int = 0 # Index of the current dialogue line being displayed.
var is_active: bool = false # Flag to check if a dialogue sequence is currently running.

func _ready():
	# Called when the node enters the scene tree for the first time.
	hide_dialogue() # Start the game with the dialogue box hidden.

func start_dialogue(dialogue_array: Array):
	# Public function to begin a new dialogue sequence.
	dialogue_data = dialogue_array # Store the array of dialogue data passed to the function.
	current_index = 0 # Start from the first line.
	is_active = true # Set the active flag to true.
	show_current_dialogue() # Display the first line of dialogue.

func show_current_dialogue():
	# Internal function to display the dialogue line at current_index.
	
	if current_index >= dialogue_data.size():
		# Check if we've gone past the last element in the array.
		end_dialogue() # If so, finish the entire dialogue sequence.
		return
	
	var current = dialogue_data[current_index] # Get the data object (dictionary) for the current line.
	dialogue_box.show() # Make the main dialogue box visible.
	
	# Set speaker name (optional)
	if current.has("speaker"):
		# Check if the current line has a "speaker" key.
		name_label.text = current.speaker # Set the speaker name label.
		name_label.show() # Make the name label visible.
	else:
		name_label.hide() # Hide the name label if no speaker is specified.
	
	# Set dialogue text
	text_label.text = current.text # Set the main dialogue text.
	
	# Handle camera pan if specified
	if current.has("camera_target"):
		# Check if the dialogue line specifies a camera movement.
		# pan_duration defaults to 1.0 if not specified in the dialogue data.
		pan_camera_to(current.camera_target, current.get("pan_duration", 1.0))
	
	continue_indicator.show() # Show the indicator that prompts the player to continue.

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

func _input(event):
	# Built-in Godot function to handle user input events.
	# Check if the dialogue is active AND the "ui_accept" action (usually mapped to Enter/Space/A button) was pressed.
	if is_active and event.is_action_pressed("ui_accept"):
		next_dialogue() # Advance to the next line of dialogue.

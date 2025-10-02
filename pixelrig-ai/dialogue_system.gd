# DialogueSystem.gd
extends CanvasLayer

signal dialogue_finished

@onready var dialogue_box = $DialogueBox
@onready var name_label = $DialogueBox/NameLabel
@onready var text_label = $DialogueBox/TextLabel
@onready var continue_indicator = $DialogueBox/ContinueIndicator

var dialogue_data: Array = []
var current_index: int = 0
var is_active: bool = false

func _ready():
	hide_dialogue()

func start_dialogue(dialogue_array: Array):
	dialogue_data = dialogue_array
	current_index = 0
	is_active = true
	show_current_dialogue()

func show_current_dialogue():
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
	
	# Set dialogue text
	text_label.text = current.text
	
	# Handle camera pan if specified
	if current.has("camera_target"):
		pan_camera_to(current.camera_target, current.get("pan_duration", 1.0))
	
	continue_indicator.show()

func hide_dialogue():
	dialogue_box.hide()
	continue_indicator.hide()

func next_dialogue():
	if not is_active:
		return
		
	current_index += 1
	show_current_dialogue()

func end_dialogue():
	is_active = false
	hide_dialogue()
	dialogue_finished.emit()

func pan_camera_to(target_position: Vector2, duration: float):
	var camera = get_viewport().get_camera_2d()
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "global_position", target_position, duration)

func _input(event):
	if is_active and event.is_action_pressed("ui_accept"):
		next_dialogue()

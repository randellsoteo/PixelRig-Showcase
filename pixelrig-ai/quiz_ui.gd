extends CanvasLayer

@onready var panel = $Panel
@onready var question_label = $Panel/Label
@onready var answers_container = $Panel/VBoxContainer

var correct_answer_index: int = 0
var player_ref: Node = null

func _ready():
	panel.visible = false

func show_quiz(player: Node, question: String, answer_list: Array, correct_index: int):
	panel.visible = true
	player_ref = player
	player_ref.can_move = false  # Disable player movement

	question_label.text = question
	correct_answer_index = correct_index

	# Clear old buttons
	for child in answers_container.get_children():
		child.queue_free()

	# Create buttons dynamically
	for i in range(answer_list.size()):
		var btn = Button.new()
		btn.text = answer_list[i]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func() -> void:
			_on_answer_pressed(i)
		)
		answers_container.add_child(btn)

func _on_answer_pressed(index: int):
	if index == correct_answer_index:
		print("✅ Correct!")
	else:
		print("❌ Wrong!")

	panel.visible = false
	if player_ref:
		player_ref.can_move = true  # Resume player movement

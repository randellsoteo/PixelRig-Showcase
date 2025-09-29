extends CanvasLayer

@onready var panel = $Panel
@onready var question_label = $Panel/Label
@onready var answers_container = $Panel/VBoxContainer
@onready var feedback_label = $Panel/FeedbackLabel

var player_ref: Node = null
var questions: Array = []   # holds all questions
var current_index: int = 0  # which question we're on

# Each question entry looks like:
# {
#   "text": "What does RAM stand for?",
#   "answers": ["Random Access Memory", "Read After Memory", "Rapid Active Module", "Run All Memory"],
#   "correct": 0
# }


func _ready():
	panel.visible = false

func show_quiz(player: Node, q_list: Array):
	panel.visible = true
	player_ref = player
	player_ref.can_move = false
	questions = q_list
	current_index = 0
	_show_question()

func _show_question():
	var q = questions[current_index]
	question_label.text = q["text"]
	feedback_label.text = ""
	
	# Clear old buttons
	for child in answers_container.get_children():
		child.queue_free()

	# Create buttons dynamically
	for i in range(q["answers"].size()):
		var btn = Button.new()
		btn.text = q["answers"][i]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func() -> void:
			_on_answer_pressed(i, q["correct"])
		)
		answers_container.add_child(btn)

func _on_answer_pressed(index: int, correct_index: int):
	if index == correct_index:
		feedback_label.text = "✅ Correct!"
		await get_tree().create_timer(0.75).timeout
		current_index += 1
		if current_index < questions.size():
			_show_question()
		else:
			# All questions answered
			panel.visible = false
			if player_ref:
				player_ref.can_move = true
	else:
		feedback_label.text = "❌ Wrong! Try again."

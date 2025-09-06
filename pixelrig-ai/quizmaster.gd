extends StaticBody2D

func interact():
	var quiz_ui = get_tree().root.get_node("World/QuizUI")
	var player = get_tree().root.get_node("World/Player")
	quiz_ui.show_quiz(player,
		"What does RAM stand for?",
		["Random Access Memory", "Read After Memory", "Rapid Active Module", "Run All Memory"],
		0
	)

extends StaticBody2D

func interact():
	var quiz_ui = get_tree().root.get_node("World/QuizUI")
	var player = get_tree().root.get_node("World/Player")
	
	var q_list = [
		{
			"text": "What does RAM stand for?",
			"answers": ["Random Access Memory", "Read After Memory", "Rapid Active Module", "Run All Memory"],
			"correct": 0
		},
		{
			"text": "What does CPU stand for?",
			"answers": ["Central Processing Unit", "Computer Personal Unit", "Central Program Utility", "Core Processing Usage"],
			"correct": 0
		},
		{
			"text": "Which device is used to store permanent data?",
			"answers": ["RAM", "Hard Drive", "Cache", "Registers"],
			"correct": 1
		}
	]

	quiz_ui.show_quiz(player, q_list)

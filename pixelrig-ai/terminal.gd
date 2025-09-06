extends StaticBody2D  # or Area2D if you want trigger area

func interact():
	var terminal_ui = get_tree().root.get_node("World/TerminalUI")
	var player = get_tree().root.get_node("World/Player")
	terminal_ui.show_terminal(player)

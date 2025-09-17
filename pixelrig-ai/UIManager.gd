extends CanvasLayer

@onready var terminal_text = $TerminalText

func show_message(msg: String, duration: float = 2.0):
	terminal_text.text = msg
	terminal_text.visible = true

	# Create timer for auto-hide
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		terminal_text.visible = false
	)

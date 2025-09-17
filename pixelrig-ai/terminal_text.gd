extends Label

func show_message(msg: String, duration: float = 2.0):
	text = msg
	
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		text = ""
	)

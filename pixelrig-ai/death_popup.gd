# DeathPopup.gd
extends Control

signal respawn_requested
signal main_menu_requested

func _ready():
	hide()
	# Pause the game when popup appears
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_popup():
	show()
	get_tree().paused = true

func hide_popup():
	hide()
	get_tree().paused = false

func _on_respawn_button_pressed():
	hide_popup()
	respawn_requested.emit()

func _on_main_menu_button_pressed():
	hide_popup()
	main_menu_requested.emit()
	# TODO: Connect to main menu scene later
	print("⚠️ Main menu not implemented yet")

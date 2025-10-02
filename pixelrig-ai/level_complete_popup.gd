# LevelCompletePopup.gd
extends Control

signal next_level_pressed
signal main_menu_pressed

@onready var component_label = $Panel/VBoxContainer/ComponentLabel
@onready var next_button = $Panel/VBoxContainer/NextLevelButton
@onready var menu_button = $Panel/VBoxContainer/MainMenuButton

func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_completion(component_name: String):
	component_label.text = component_name + " installed successfully!"
	show()
	get_tree().paused = true

func _on_next_level_button_pressed():
	hide()
	get_tree().paused = false
	next_level_pressed.emit()

func _on_main_menu_button_pressed():
	hide()
	get_tree().paused = false
	main_menu_pressed.emit()

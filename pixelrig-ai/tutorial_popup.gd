# TutorialPopup.gd
extends Control

signal lets_go_pressed

@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var wasd_label = $Panel/VBoxContainer/WASDLabel
@onready var space_label = $Panel/VBoxContainer/SpaceLabel
@onready var e_label = $Panel/VBoxContainer/ELabel
@onready var lets_go_button = $Panel/VBoxContainer/LetsGoButton

func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_tutorial():
	show()
	get_tree().paused = false

func hide_tutorial():
	hide()
	get_tree().paused = false

func _on_lets_go_button_pressed():
	hide_tutorial()
	lets_go_pressed.emit()

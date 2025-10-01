# InstructionPopup.gd
extends Control

signal instruction_dismissed

@onready var label = $Panel/Label # Adjust path based on your design

func _ready():
	# Start hidden
	hide()

func show_popup():
	show()
	# Optional: Set the label text here if it changes often
	label.text = "Use WASD to move and Space to attack. Good luck!"
	# Give the control focus so it receives input
	grab_focus()

func _input(event):
	# Check if the panel is visible and the player presses "ui_accept"
	if visible and event.is_action_pressed("ui_accept"):
		hide()
		instruction_dismissed.emit()

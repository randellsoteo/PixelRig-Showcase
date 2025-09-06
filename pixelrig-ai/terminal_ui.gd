extends CanvasLayer

@onready var panel = $Panel
@onready var title_label = $Panel/Label
@onready var content_label = $Panel/RichTextLabel

var player_ref: Node = null

func _ready():
	panel.visible = false

func show_terminal(player: Node):
	panel.visible = true
	player_ref = player
	player_ref.can_move = false  # block player movement

	title_label.text = "Info Terminal"
	content_label.text = "This is a placeholder for informational content.\nYou can show details about components, instructions, or fun facts here."

func close_terminal():
	panel.visible = false
	if player_ref:
		player_ref.can_move = true  # resume player
		player_ref = null


func _on_Closebutton_pressed() -> void:
	close_terminal()

# PCTerminal.gd - The endpoint where player deposits components
extends Area2D

@export var required_component_id: String = "cpu"  # What this terminal needs
@onready var label = $Label if has_node("Label") else null

var component_deposited: bool = false

func _ready():
	update_label()

func interact():
	if component_deposited:
		print("Component already installed!")
		return
	
	# Check if player has the right component
	if not SolutionItem.has_item():
		print("You need a component to install here!")
		show_message("Bring the component from the Quizmaster first!")
		return
	
	var item = SolutionItem.get_current_item()
	
	# Check if it's a component (not a tool)
	if item.type != SolutionItem.ItemType.COMPONENT:
		print("This terminal needs a component, not a tool!")
		show_message("This needs a PC component!")
		return
	
	# Check if it's the correct component
	if item.id != required_component_id:
		print("Wrong component! This terminal needs:", required_component_id)
		show_message("This terminal needs a " + required_component_id.to_upper())
		return
	
	# Success! Deposit component
	if SolutionItem.deposit_item():
		component_deposited = true
		print("Component installed successfully!")
		update_label()
		complete_level()

func complete_level():
	# Show completion popup
	var world = get_tree().current_scene
	if world and world.has_method("show_level_complete"):
		world.show_level_complete()
	else:
		print("LEVEL COMPLETE!")

func update_label():
	if label:
		if component_deposited:
			label.text = "Component Installed ✓"
			label.modulate = Color.GREEN
		else:
			label.text = "Insert " + required_component_id.to_upper()
			label.modulate = Color.YELLOW

func show_message(msg: String):
	# Quick temporary message
	print("Terminal:", msg)
	# You can create a floating label here if you want

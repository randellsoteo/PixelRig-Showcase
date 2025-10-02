# quizmaster.gd
extends Area2D

@export var level_id: String = "level_1"  # Configure per level
@export var reward_type: String = "component"  # "component" or "tool"
@export var reward_id: String = "cpu"  # cpu, ram, wrench, extinguisher, etc.

var quiz_completed: bool = false

func interact():
	if quiz_completed:
		print("You already completed this quiz!")
		return
	
	var quiz_ui = get_tree().root.get_node("World/QuizUI")
	var player = get_tree().root.get_node("World/Player")
	
	# Quiz questions - customize per level
	var q_list = [
		{
			"text": "What does CPU stand for?",
			"answers": ["Central Processing Unit", "Computer Personal Unit", "Central Program Utility", "Core Processing Usage"],
			"correct": 0
		},
		{
			"text": "What is the CPU's primary function?",
			"answers": ["Store data", "Process instructions", "Display graphics", "Connect to internet"],
			"correct": 1
		},
		{
			"text": "Which component is known as the 'brain' of the computer?",
			"answers": ["RAM", "Hard Drive", "CPU", "Motherboard"],
			"correct": 2
		}
	]
	
	# Show quiz and connect to completion signal
	quiz_ui.quiz_completed.connect(_on_quiz_completed)
	quiz_ui.show_quiz(player, q_list)

func _on_quiz_completed(score: int, total: int):
	quiz_completed = true
	print("Quiz completed! Score:", score, "/", total)
	
	# Give reward based on type
	if reward_type == "component":
		_give_component()
	elif reward_type == "tool":
		_give_tool()

func _give_component():
	var component_data = {
		"type": SolutionItem.ItemType.COMPONENT,
		"id": reward_id,
		"name": _get_component_name(reward_id),
		"description": "A critical PC component. Deliver it to the terminal.",
		"icon": "res://icons/" + reward_id + ".png"
	}
	SolutionItem.receive_item(component_data)

func _give_tool():
	var tool_data = {
		"type": SolutionItem.ItemType.TOOL,
		"id": reward_id,
		"name": _get_tool_name(reward_id),
		"description": "Use this tool to clear obstacles.",
		"icon": "res://icons/" + reward_id + ".png"
	}
	SolutionItem.receive_item(tool_data)

func _get_component_name(id: String) -> String:
	match id:
		"cpu": return "CPU"
		"ram": return "RAM"
		"gpu": return "GPU"
		"motherboard": return "Motherboard"
		"psu": return "Power Supply"
		"storage": return "Storage Drive"
		_: return "Unknown Component"

func _get_tool_name(id: String) -> String:
	match id:
		"wrench": return "Wrench"
		"extinguisher": return "Fire Extinguisher"
		"vacuum": return "Vacuum Cleaner"
		"multimeter": return "Multimeter"
		_: return "Unknown Tool"

extends Node

@onready var current_scene : Node = $Title

@onready var fade : ColorRect = $Fade

@onready var lobby_resource := preload("res://scenes/lobby.tscn")
@onready var game_resource := preload("res://scenes/game.tscn")

func _ready() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(fade,"modulate",Color(1,1,1,0),0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func _on_title_login(tokens: Array) -> void:
	_switch_to_scene(lobby_resource)

func _on_lobby_enter_game(board : Array[PackedByteArray]) -> void:
	var game : Node3D = _switch_to_scene(game_resource)
	var pann : Node3D = game.get_node("Pann")
	pann.state_pann = board

func _switch_to_scene(packed_scene:PackedScene) -> Node:
	var tween = get_tree().create_tween()
	var new_scene = packed_scene.instantiate()
	tween.tween_property(fade,"modulate",Color(1,1,1,1),0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func()->void : 
		current_scene.queue_free()
		self.add_child(new_scene)
		self.move_child(new_scene,0)
		current_scene = new_scene
		)
	tween.tween_property(fade,"modulate",Color(1,1,1,0),0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	return new_scene

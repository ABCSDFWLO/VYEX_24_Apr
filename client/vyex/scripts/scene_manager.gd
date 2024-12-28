extends Node

@onready var title : Control = $Title

@onready var lobby_resource = preload("res://scenes/lobby.tscn")



func _on_control_login(tokens: Array) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(title,"modulate",Color(1,1,1,1),0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
